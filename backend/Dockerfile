FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies including curl for healthcheck
RUN apt-get update && apt-get install -y \
    gcc \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY backend/requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY backend/app ./app

# Copy startup script
COPY backend/start.sh /app/start.sh
RUN chmod +x /app/start.sh

# Expose port (Railway will override this with PORT env var)
EXPOSE 8000

# Run the application using startup script
CMD ["/app/start.sh"]
