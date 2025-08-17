# Multi-platform Docker image for Paper Search MCP Server
FROM python:3.10-slim

# Install system dependencies needed for packages
RUN apt-get update && apt-get install -y \
    build-essential \
    libxml2-dev \
    libxslt-dev \
    libssl-dev \
    libffi-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy dependency files first for better caching
COPY pyproject.toml ./
COPY README.md ./

# Install Python dependencies
RUN pip install --upgrade pip \
    && pip install --no-cache-dir .

# Copy the application code
COPY paper_search_mcp/ ./paper_search_mcp/

# Create non-root user for security
RUN useradd --create-home --shell /bin/bash mcp \
    && chown -R mcp:mcp /app

USER mcp

# Set environment variables
ENV PYTHONPATH=/app
ENV PYTHONUNBUFFERED=1

# Health check to verify the server can start
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD echo '{"method": "initialize", "params": {"protocolVersion": "2024-11-05", "capabilities": {}, "clientInfo": {"name": "test", "version": "1.0.0"}}}' | python -m paper_search_mcp.server || exit 1

# Command to run the MCP server
CMD ["python", "-m", "paper_search_mcp.server"]
