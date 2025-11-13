"""
Configuration management for DocExtract backend
"""
from pydantic_settings import BaseSettings
from typing import List


class Settings(BaseSettings):
    """Application settings loaded from environment variables"""

    # MongoDB Configuration
    mongodb_url: str = "mongodb://localhost:27017"
    mongodb_db_name: str = "docextract"

    # LlamaParse Configuration
    llama_cloud_api_key: str

    # Server Configuration
    host: str = "0.0.0.0"
    port: int = 8000

    # CORS Configuration
    # Can be overridden with ALLOWED_ORIGINS env var (comma-separated)
    allowed_origins: List[str] = ["*"]  # Allow all origins for development

    # API Configuration
    api_v1_prefix: str = "/api/v1"

    class Config:
        env_file = ".env"
        case_sensitive = False


# Global settings instance
settings = Settings()
