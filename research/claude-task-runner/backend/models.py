"""Data models for Claude Task Runner."""
from datetime import datetime
from enum import Enum
from typing import Optional
from uuid import UUID, uuid4
from pydantic import BaseModel, Field


class TaskStatus(str, Enum):
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"


class TaskBase(BaseModel):
    """Base task model for creation."""
    prompt: str = Field(..., description="The Claude Code prompt to execute")
    working_directory: Optional[str] = Field(
        None, 
        description="Working directory for Claude Code execution"
    )
    timeout: Optional[int] = Field(
        None, 
        description="Timeout in seconds for execution"
    )
    callback_url: Optional[str] = Field(
        None,
        description="URL to POST result when completed"
    )


class TaskCreate(TaskBase):
    """Model for creating a new task."""
    pass


class Task(TaskBase):
    """Full task model with all fields."""
    id: UUID = Field(default_factory=uuid4)
    status: TaskStatus = TaskStatus.PENDING
    result: Optional[str] = None
    error: Optional[str] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True


class TaskResponse(BaseModel):
    """Response model for task API."""
    id: UUID
    prompt: str
    status: TaskStatus
    result: Optional[str] = None
    error: Optional[str] = None
    created_at: datetime
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    working_directory: Optional[str] = None
    timeout: Optional[int] = None
    callback_url: Optional[str] = None
    
    class Config:
        orm_mode = True


class TaskListResponse(BaseModel):
    """Response model for task list API."""
    tasks: list[TaskResponse]
    total: int
    page: int
    page_size: int


class StatsResponse(BaseModel):
    """Response model for stats API."""
    total_tasks: int
    pending: int
    running: int
    completed: int
    failed: int
    cancelled: int
