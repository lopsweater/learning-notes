"""Task queue and worker for processing tasks."""
import asyncio
import logging
from datetime import datetime
from typing import Optional
import httpx

from .models import Task, TaskStatus
from .database import db
from .claude_runner import runner
from .config import config

logger = logging.getLogger(__name__)


class TaskQueue:
    """Async task queue with worker."""
    
    def __init__(self):
        self.queue: asyncio.Queue = asyncio.Queue()
        self.running = False
        self.current_task: Optional[Task] = None
        self.worker_task: Optional[asyncio.Task] = None
    
    async def start(self):
        """Start the task worker."""
        if self.running:
            return
        
        self.running = True
        self.worker_task = asyncio.create_task(self._worker())
        logger.info("Task queue worker started")
        
        # Load pending tasks from database
        pending_tasks = db.get_pending_tasks()
        for task in pending_tasks:
            await self.queue.put(task)
            logger.info(f"Loaded pending task {task.id} into queue")
    
    async def stop(self):
        """Stop the task worker."""
        self.running = False
        if self.worker_task:
            self.worker_task.cancel()
            try:
                await self.worker_task
            except asyncio.CancelledError:
                pass
        logger.info("Task queue worker stopped")
    
    async def enqueue(self, task: Task):
        """Add a task to the queue."""
        await self.queue.put(task)
        logger.info(f"Task {task.id} enqueued (queue size: {self.queue.qsize()})")
    
    async def _worker(self):
        """Worker coroutine that processes tasks."""
        while self.running:
            try:
                # Wait for a task with timeout to allow checking self.running
                try:
                    task = await asyncio.wait_for(self.queue.get(), timeout=1.0)
                except asyncio.TimeoutError:
                    continue
                
                await self._process_task(task)
                
            except asyncio.CancelledError:
                break
            except Exception as e:
                logger.exception("Worker error")
    
    async def _process_task(self, task: Task):
        """Process a single task."""
        self.current_task = task
        
        try:
            # Update status to running
            task.status = TaskStatus.RUNNING
            task.started_at = datetime.utcnow()
            db.update_task(task)
            logger.info(f"Processing task {task.id}")
            
            # Execute Claude Code
            result, error = await runner.execute(task)
            
            # Update task with result
            task.result = result
            task.error = error
            task.status = TaskStatus.FAILED if error else TaskStatus.COMPLETED
            task.completed_at = datetime.utcnow()
            db.update_task(task)
            
            logger.info(f"Task {task.id} {task.status.value}")
            
            # Send callback if configured
            if task.callback_url:
                await self._send_callback(task)
                
        except Exception as e:
            logger.exception(f"Error processing task {task.id}")
            task.status = TaskStatus.FAILED
            task.error = str(e)
            task.completed_at = datetime.utcnow()
            db.update_task(task)
            
        finally:
            self.current_task = None
    
    async def _send_callback(self, task: Task):
        """Send result to callback URL."""
        try:
            async with httpx.AsyncClient() as client:
                await client.post(
                    task.callback_url,
                    json={
                        "id": str(task.id),
                        "status": task.status.value,
                        "result": task.result,
                        "error": task.error,
                        "completed_at": task.completed_at.isoformat() if task.completed_at else None,
                    },
                    timeout=30.0,
                )
                logger.info(f"Callback sent for task {task.id}")
        except Exception as e:
            logger.error(f"Callback failed for task {task.id}: {e}")
    
    def get_queue_size(self) -> int:
        """Get current queue size."""
        return self.queue.qsize()
    
    def is_processing(self) -> bool:
        """Check if a task is currently being processed."""
        return self.current_task is not None


# Global task queue instance
task_queue = TaskQueue()
