"""Database operations for Claude Task Runner."""
import sqlite3
import json
from datetime import datetime
from pathlib import Path
from typing import Optional
from uuid import UUID

from .models import Task, TaskStatus, TaskCreate
from .config import config


class Database:
    """SQLite database manager for tasks."""
    
    def __init__(self, db_path: Optional[str] = None):
        self.db_path = db_path or config.database.path
        self._ensure_db_dir()
        self._init_db()
    
    def _ensure_db_dir(self):
        """Ensure database directory exists."""
        db_file = Path(self.db_path)
        db_file.parent.mkdir(parents=True, exist_ok=True)
    
    def _get_connection(self) -> sqlite3.Connection:
        """Get database connection."""
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        return conn
    
    def _init_db(self):
        """Initialize database tables."""
        conn = self._get_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS tasks (
                id TEXT PRIMARY KEY,
                prompt TEXT NOT NULL,
                status TEXT NOT NULL DEFAULT 'pending',
                result TEXT,
                error TEXT,
                created_at TEXT NOT NULL,
                started_at TEXT,
                completed_at TEXT,
                working_directory TEXT,
                timeout INTEGER,
                callback_url TEXT
            )
        """)
        
        # Create indexes
        cursor.execute("""
            CREATE INDEX IF NOT EXISTS idx_tasks_status 
            ON tasks(status)
        """)
        cursor.execute("""
            CREATE INDEX IF NOT EXISTS idx_tasks_created_at 
            ON tasks(created_at)
        """)
        
        conn.commit()
        conn.close()
    
    def create_task(self, task_create: TaskCreate) -> Task:
        """Create a new task."""
        task = Task(
            prompt=task_create.prompt,
            working_directory=task_create.working_directory,
            timeout=task_create.timeout,
            callback_url=task_create.callback_url,
        )
        
        conn = self._get_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            INSERT INTO tasks 
            (id, prompt, status, created_at, working_directory, timeout, callback_url)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, (
            str(task.id),
            task.prompt,
            task.status.value,
            task.created_at.isoformat(),
            task.working_directory,
            task.timeout,
            task.callback_url,
        ))
        
        conn.commit()
        conn.close()
        
        return task
    
    def get_task(self, task_id: UUID) -> Optional[Task]:
        """Get a task by ID."""
        conn = self._get_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            SELECT * FROM tasks WHERE id = ?
        """, (str(task_id),))
        
        row = cursor.fetchone()
        conn.close()
        
        if row is None:
            return None
        
        return self._row_to_task(row)
    
    def list_tasks(
        self, 
        status: Optional[TaskStatus] = None,
        page: int = 1, 
        page_size: int = 20
    ) -> tuple[list[Task], int]:
        """List tasks with pagination."""
        conn = self._get_connection()
        cursor = conn.cursor()
        
        # Count query
        if status:
            cursor.execute("""
                SELECT COUNT(*) FROM tasks WHERE status = ?
            """, (status.value,))
        else:
            cursor.execute("SELECT COUNT(*) FROM tasks")
        
        total = cursor.fetchone()[0]
        
        # Data query
        offset = (page - 1) * page_size
        
        if status:
            cursor.execute("""
                SELECT * FROM tasks 
                WHERE status = ?
                ORDER BY created_at DESC
                LIMIT ? OFFSET ?
            """, (status.value, page_size, offset))
        else:
            cursor.execute("""
                SELECT * FROM tasks 
                ORDER BY created_at DESC
                LIMIT ? OFFSET ?
            """, (page_size, offset))
        
        rows = cursor.fetchall()
        conn.close()
        
        tasks = [self._row_to_task(row) for row in rows]
        return tasks, total
    
    def update_task(self, task: Task) -> Task:
        """Update a task."""
        conn = self._get_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            UPDATE tasks SET
                status = ?,
                result = ?,
                error = ?,
                started_at = ?,
                completed_at = ?,
                working_directory = ?,
                timeout = ?
            WHERE id = ?
        """, (
            task.status.value,
            task.result,
            task.error,
            task.started_at.isoformat() if task.started_at else None,
            task.completed_at.isoformat() if task.completed_at else None,
            task.working_directory,
            task.timeout,
            str(task.id),
        ))
        
        conn.commit()
        conn.close()
        
        return task
    
    def delete_task(self, task_id: UUID) -> bool:
        """Delete a task."""
        conn = self._get_connection()
        cursor = conn.cursor()
        
        cursor.execute("DELETE FROM tasks WHERE id = ?", (str(task_id),))
        
        deleted = cursor.rowcount > 0
        conn.commit()
        conn.close()
        
        return deleted
    
    def get_stats(self) -> dict:
        """Get task statistics."""
        conn = self._get_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            SELECT status, COUNT(*) as count 
            FROM tasks 
            GROUP BY status
        """)
        
        rows = cursor.fetchall()
        conn.close()
        
        stats = {
            "total_tasks": 0,
            "pending": 0,
            "running": 0,
            "completed": 0,
            "failed": 0,
            "cancelled": 0,
        }
        
        for row in rows:
            status = row["status"]
            count = row["count"]
            stats["total_tasks"] += count
            if status in stats:
                stats[status] = count
        
        return stats
    
    def get_pending_tasks(self) -> list[Task]:
        """Get all pending tasks ordered by creation time."""
        conn = self._get_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            SELECT * FROM tasks 
            WHERE status = 'pending'
            ORDER BY created_at ASC
        """)
        
        rows = cursor.fetchall()
        conn.close()
        
        return [self._row_to_task(row) for row in rows]
    
    def _row_to_task(self, row: sqlite3.Row) -> Task:
        """Convert database row to Task model."""
        return Task(
            id=UUID(row["id"]),
            prompt=row["prompt"],
            status=TaskStatus(row["status"]),
            result=row["result"],
            error=row["error"],
            created_at=datetime.fromisoformat(row["created_at"]),
            started_at=datetime.fromisoformat(row["started_at"]) if row["started_at"] else None,
            completed_at=datetime.fromisoformat(row["completed_at"]) if row["completed_at"] else None,
            working_directory=row["working_directory"],
            timeout=row["timeout"],
            callback_url=row["callback_url"],
        )


# Global database instance
db = Database()
