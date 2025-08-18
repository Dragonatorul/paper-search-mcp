# Build stage: compile wheels and install build deps
FROM python:3.12-slim AS builder

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential \
    libxml2-dev \
    libxslt-dev \
    libssl-dev \
    libffi-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Copy project metadata and build wheels for deterministic install
COPY pyproject.toml README.md ./
COPY paper_search_mcp/ ./paper_search_mcp/

RUN python -m pip install --upgrade pip build wheel setuptools && \
    python -m build --wheel --outdir /wheels .

# Runtime stage: minimal image with only runtime deps and package installed
FROM python:3.12-slim AS runtime

WORKDIR /app

# Install runtime system packages only
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    libxml2 \
    libxslt1.1 \
    libssl1.1 \
    libffi7 \
    && rm -rf /var/lib/apt/lists/* || true

# Copy wheel from builder and install without cache
COPY --from=builder /wheels /wheels
RUN python -m pip install --upgrade pip && \
    pip install --no-cache-dir /wheels/*.whl

# Copy only what we need (installed package is in site-packages)
# Create non-root user for security
RUN useradd --create-home --shell /bin/bash mcp || true

USER mcp

# Set environment variables
ENV PYTHONUNBUFFERED=1

# Health check to verify the server can start
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD echo '{"method": "initialize", "params": {"protocolVersion": "2024-11-05", "capabilities": {}, "clientInfo": {"name": "test", "version": "1.0.0"}}}' | python -m paper_search_mcp.server || exit 1

# Command to run the MCP server
CMD ["python", "-m", "paper_search_mcp.server"]
