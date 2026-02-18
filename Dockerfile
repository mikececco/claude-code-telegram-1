FROM python:3.12-slim

# Install Node.js (required by claude-agent-sdk which wraps the CLI) and system deps
RUN apt-get update && apt-get install -y --no-install-recommends curl git && \
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    npm install -g @anthropic-ai/claude-code && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Poetry
RUN pip install --no-cache-dir poetry

WORKDIR /app
COPY pyproject.toml poetry.lock ./
RUN poetry config virtualenvs.create false && \
    poetry install --only main --no-interaction --no-root

COPY . .

# Create directories for SQLite DB and project files
RUN mkdir -p /app/data /app/projects

ENV APPROVED_DIRECTORY=/app/projects
ENV USE_SDK=true

CMD ["python", "-m", "src.main"]
