"""Claude Code CLI runner."""
import asyncio
import subprocess
import shutil
import logging
from datetime import datetime
from typing import Optional, Tuple

from .models import Task, TaskStatus
from .config import config

logger = logging.getLogger(__name__)


class ClaudeRunner:
    """Execute tasks using Claude Code CLI."""
    
    def __init__(self):
        self.cli_path = config.claude.cli_path
        self.default_timeout = config.claude.timeout
        self.default_working_dir = config.claude.default_working_dir
        self._check_cli_available()
    
    def _check_cli_available(self):
        """Check if Claude Code CLI is available."""
        if shutil.which(self.cli_path) is None:
            logger.warning(
                f"Claude Code CLI not found at '{self.cli_path}'. "
                "Make sure Claude Code is installed and in PATH."
            )
    
    async def execute(self, task: Task) -> Tuple[str, Optional[str]]:
        """
        Execute a task using Claude Code.
        
        Returns:
            Tuple of (result, error)
        """
        timeout = task.timeout or self.default_timeout
        working_dir = task.working_directory or self.default_working_dir
        
        logger.info(f"Executing task {task.id} with timeout {timeout}s")
        logger.debug(f"Prompt: {task.prompt[:100]}...")
        
        try:
            # Run Claude Code CLI
            process = await asyncio.create_subprocess_exec(
                self.cli_path,
                "--print",
                task.prompt,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
                cwd=working_dir,
            )
            
            try:
                stdout, stderr = await asyncio.wait_for(
                    process.communicate(),
                    timeout=timeout
                )
            except asyncio.TimeoutError:
                process.kill()
                await process.wait()
                raise TimeoutError(f"Task timed out after {timeout} seconds")
            
            result = stdout.decode("utf-8", errors="replace")
            error_output = stderr.decode("utf-8", errors="replace")
            
            if process.returncode != 0:
                error_msg = error_output or f"Claude Code exited with code {process.returncode}"
                logger.error(f"Task {task.id} failed: {error_msg}")
                return result, error_msg
            
            logger.info(f"Task {task.id} completed successfully")
            return result, None
            
        except FileNotFoundError:
            error_msg = f"Claude Code CLI not found at '{self.cli_path}'"
            logger.error(error_msg)
            return "", error_msg
        except Exception as e:
            error_msg = f"Unexpected error: {str(e)}"
            logger.exception(f"Task {task.id} failed with exception")
            return "", error_msg


# Global runner instance
runner = ClaudeRunner()
