"""Main FastAPI application for Claude Task Runner."""
import logging
from contextlib import asynccontextmanager
from datetime import datetime
from pathlib import Path
from typing import Optional

from fastapi import FastAPI, HTTPException, Query
from fastapi.staticfiles import StaticFiles
from fastapi.responses import HTMLResponse, FileResponse
from fastapi.middleware.cors import CORSMiddleware

from .config import config
from .models import (
    TaskCreate, 
    TaskResponse, 
    TaskListResponse, 
    TaskStatus,
    StatsResponse,
    Task,
)
from .database import db
from .task_queue import task_queue

# Setup logging
logging.basicConfig(
    level=getattr(logging, config.logging.level),
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan handler."""
    # Startup
    logger.info("Starting Claude Task Runner...")
    await task_queue.start()
    logger.info("Claude Task Runner started")
    
    yield
    
    # Shutdown
    logger.info("Stopping Claude Task Runner...")
    await task_queue.stop()
    logger.info("Claude Task Runner stopped")


# Create FastAPI app
app = FastAPI(
    title="Claude Task Runner",
    description="A web-based task runner for Claude Code",
    version="1.0.0",
    lifespan=lifespan,
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ==================== API Routes ====================

@app.post("/api/tasks", response_model=TaskResponse)
async def create_task(task_create: TaskCreate):
    """Create a new task."""
    task = db.create_task(task_create)
    await task_queue.enqueue(task)
    logger.info(f"Created task {task.id}")
    return TaskResponse.from_orm(task)


@app.get("/api/tasks", response_model=TaskListResponse)
async def list_tasks(
    status: Optional[TaskStatus] = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
):
    """List tasks with pagination."""
    tasks, total = db.list_tasks(status=status, page=page, page_size=page_size)
    return TaskListResponse(
        tasks=[TaskResponse.from_orm(t) for t in tasks],
        total=total,
        page=page,
        page_size=page_size,
    )


@app.get("/api/tasks/{task_id}", response_model=TaskResponse)
async def get_task(task_id: str):
    """Get a task by ID."""
    from uuid import UUID
    try:
        task_uuid = UUID(task_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid task ID")
    
    task = db.get_task(task_uuid)
    if task is None:
        raise HTTPException(status_code=404, detail="Task not found")
    
    return TaskResponse.from_orm(task)


@app.delete("/api/tasks/{task_id}")
async def delete_task(task_id: str):
    """Delete a task."""
    from uuid import UUID
    try:
        task_uuid = UUID(task_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid task ID")
    
    # Check if task exists and is not running
    task = db.get_task(task_uuid)
    if task is None:
        raise HTTPException(status_code=404, detail="Task not found")
    
    if task.status == TaskStatus.RUNNING:
        raise HTTPException(status_code=400, detail="Cannot delete running task")
    
    deleted = db.delete_task(task_uuid)
    if not deleted:
        raise HTTPException(status_code=404, detail="Task not found")
    
    return {"message": "Task deleted"}


@app.post("/api/tasks/{task_id}/cancel")
async def cancel_task(task_id: str):
    """Cancel a running task."""
    from uuid import UUID
    try:
        task_uuid = UUID(task_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid task ID")
    
    task = db.get_task(task_uuid)
    if task is None:
        raise HTTPException(status_code=404, detail="Task not found")
    
    if task.status not in [TaskStatus.PENDING, TaskStatus.RUNNING]:
        raise HTTPException(status_code=400, detail="Can only cancel pending or running tasks")
    
    task.status = TaskStatus.CANCELLED
    task.completed_at = datetime.utcnow()
    db.update_task(task)
    
    return {"message": "Task cancelled"}


@app.get("/api/stats", response_model=StatsResponse)
async def get_stats():
    """Get task statistics."""
    stats = db.get_stats()
    return StatsResponse(**stats)


@app.get("/api/queue/status")
async def get_queue_status():
    """Get queue status."""
    return {
        "queue_size": task_queue.get_queue_size(),
        "is_processing": task_queue.is_processing(),
        "current_task": str(task_queue.current_task.id) if task_queue.current_task else None,
    }


# ==================== Frontend Routes ====================

# Get frontend path based on config
def get_frontend_path() -> Path:
    """Get frontend directory path based on mode."""
    base_path = Path(__file__).parent.parent / "frontend"
    mode = config.frontend.mode
    return base_path / mode


# Mount static files for frontend
frontend_path = get_frontend_path()
if frontend_path.exists():
    app.mount("/static", StaticFiles(directory=str(frontend_path)), name="static")


@app.get("/", response_class=HTMLResponse)
async def index():
    """Serve the main page."""
    index_file = get_frontend_path() / "index.html"
    if index_file.exists():
        return FileResponse(str(index_file))
    return HTMLResponse(
        content="<h1>Frontend not found</h1><p>Please check frontend configuration.</p>",
        status_code=404,
    )


# ==================== Health Check ====================

@app.get("/health")
async def health():
    """Health check endpoint."""
    return {"status": "ok"}


# ==================== Main Entry ====================

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host=config.server.host,
        port=config.server.port,
        reload=True,
    )
