# Multi-stage build for Node.js version selection
FROM ubuntu:22.04 AS base

# Metadata about the image
LABEL author="nueva" \
      maintainer="admin@nueva.my.id" \
      description="A Docker image for running Node.js applications with PM2 and essential utilities, supporting multiple Node.js versions."

# Set environment variables to avoid user interaction during installation
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=UTC \
    LANGUAGE=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# Update and install core dependencies
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y \
    # Base utilities
    curl wget gnupg git unzip zip tar \
    # Development tools
    build-essential pkg-config python3 python3-dev python3-pip \
    # Network utilities
    iputils-ping dnsutils net-tools iproute2 netcat-openbsd \
    # System utilities
    locales tzdata ca-certificates sudo \
    # Database support
    sqlite3 libsqlite3-dev \
    # Media processing
    ffmpeg imagemagick \
    # Text processing
    jq vim nano \
    # Additional useful tools
    htop procps lsof \
    # Cleanup to reduce image size
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set up locale
RUN locale-gen en_US.UTF-8

# Create a non-root user 'container' with sudo privileges
RUN useradd -m -d /home/container -s /bin/bash container && \
    echo "container ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/container

# Install Node Version Manager (NVM) for multiple Node.js versions
ENV NVM_DIR /usr/local/nvm
RUN mkdir -p $NVM_DIR && \
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

# Install Node.js versions 20-22 using NVM
RUN . $NVM_DIR/nvm.sh && \
    # Install LTS Node.js versions
    nvm install 20 && \
    nvm install 22 && \
    # Set default to Node.js 20
    nvm alias default 20 && \
    # Install global packages for all Node.js versions
    nvm use 20 && npm install -g pm2@latest yarn@latest pnpm@latest && \
    nvm use 22 && npm install -g pm2@latest yarn@latest pnpm@latest

# Copy NVM configuration to container user's home and set proper permissions
RUN cp -R $NVM_DIR /home/container/nvm && \
    chown -R container:container /home/container/nvm && \
    chmod -R 755 /home/container/nvm

# Create working directory and set permissions
RUN mkdir -p /home/container && \
    chown -R container:container /home/container

# Switch to container user
USER container
WORKDIR /home/container

# Add NVM to container user's bash profile with proper sourcing
RUN echo 'export NVM_DIR="/home/container/nvm"' >> /home/container/.bashrc && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> /home/container/.bashrc && \
    echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> /home/container/.bashrc && \
    echo 'export PATH="$NVM_DIR/versions/node/$(nvm version default)/bin:$PATH"' >> /home/container/.bashrc

# Copy the entrypoint script with proper ownership
COPY --chown=container:container ./entrypoint.sh /entrypoint.sh

# Make the entrypoint script executable
USER root
RUN chmod +x /entrypoint.sh

# Switch back to container user
USER container

# Set environment variables with proper NVM integration
ENV USER=container \
    HOME=/home/container \
    NVM_DIR=/home/container/nvm

# Health check to ensure the container is working properly
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node --version || exit 1

# Expose common ports (can be overridden)
EXPOSE 3000 8000 8080

# Specify the entrypoint
ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]