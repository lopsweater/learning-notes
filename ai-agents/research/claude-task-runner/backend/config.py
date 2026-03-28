"""Configuration management for Claude Task Runner."""
import os
import yaml
from pathlib import Path
from typing import Optional
from pydantic import BaseModel


class ServerConfig(BaseModel):
    host: str = "0.0.0.0"
    port: int = 3000


class FrontendConfig(BaseModel):
    mode: str = "simple"  # simple, vue, react


class ClaudeConfig(BaseModel):
    timeout: int = 300
    default_working_dir: str = "/root/learning-notes"
    cli_path: str = "claude"


class DatabaseConfig(BaseModel):
    path: str = "./data/tasks.db"


class LoggingConfig(BaseModel):
    level: str = "INFO"


class Config(BaseModel):
    server: ServerConfig = ServerConfig()
    frontend: FrontendConfig = FrontendConfig()
    claude: ClaudeConfig = ClaudeConfig()
    database: DatabaseConfig = DatabaseConfig()
    logging: LoggingConfig = LoggingConfig()


def load_config(config_path: Optional[str] = None) -> Config:
    """Load configuration from YAML file."""
    if config_path is None:
        # Default config path
        config_path = os.environ.get(
            "CLAUDE_TASK_RUNNER_CONFIG",
            str(Path(__file__).parent.parent / "config.yaml")
        )
    
    config_file = Path(config_path)
    
    if config_file.exists():
        with open(config_file, "r", encoding="utf-8") as f:
            data = yaml.safe_load(f) or {}
        return Config(**data)
    
    return Config()


# Global config instance
config = load_config()
