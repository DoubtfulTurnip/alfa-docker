FROM python:3.9-slim

# Set labels
LABEL maintainer="ALFA Docker"
LABEL description="ALFA - Automated Audit Log Forensic Analysis for Google Workspace"

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Clone ALFA from GitHub
RUN git clone https://github.com/invictus-ir/ALFA.git /app/ALFA

# Set working directory to ALFA
WORKDIR /app/ALFA

# Install ALFA package
RUN pip install --no-cache-dir -e .

# Set working directory back to /app for project management
WORKDIR /app

# Expose OAuth callback port
EXPOSE 8089

# Create volume mount points for projects and config
VOLUME ["/projects", "/app/config"]

# Default command - start bash shell for interactive use
CMD ["/bin/bash"]
