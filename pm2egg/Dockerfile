# Multi-stage build for Node.js with multiple versions support
FROM debian:bullseye-slim AS base

# Metadata about the image
LABEL maintainer="admin@nueva.my.id" \
      description="Advanced Docker image for running Node.js applications with multiple Node.js version support, PM2, and essential utilities." \
      version="2.0.0" \
      org.opencontainers.image.source="https://github.com/nueeva/egg"

# Install basic dependencies and cleanup in one layer to reduce image size
RUN apt-get update && apt-get -y install --no-install-recommends \
        ffmpeg \
        iproute2 \
        git \
        sqlite3 \
        libsqlite3-dev \
        python3 \
        python3-dev \
        python3-pip \
        ca-certificates \
        dnsutils \
        tzdata \
        zip \
        unzip \
        tar \
        curl \
        wget \
        gnupg \
        build-essential \
        libtool \
        iputils-ping \
        nano \
        vim \
        procps \
        htop \
        net-tools \
        lsb-release \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /opt/nvm

# Install Node Version Manager (NVM) for multiple Node.js versions
ENV NVM_DIR=/opt/nvm
ENV NVM_VERSION=0.39.7

RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh | bash \
    && . "$NVM_DIR/nvm.sh" \
    && nvm install 14 \
    && nvm install 16 \
    && nvm install 18 \
    && nvm install 20 \
    && nvm alias default 20 \
    && nvm use default

# Add NVM to path and configure environment
ENV NODE_PATH=$NVM_DIR/versions/node/v20.11.1/lib/node_modules
ENV PATH=$NVM_DIR/versions/node/v20.11.1/bin:$PATH

# Install PM2 globally for all Node.js versions
RUN . "$NVM_DIR/nvm.sh" \
    && nvm use 14 && npm install -g npm@latest && npm install -g pm2 \
    && nvm use 16 && npm install -g npm@latest && npm install -g pm2 \
    && nvm use 18 && npm install -g npm@latest && npm install -g pm2 \
    && nvm use 20 && npm install -g npm@latest && npm install -g pm2

# Create a non-root user 'container' and set home directory
RUN useradd -m -d /home/container container

# Copy NVM and Node.js setups to the user directory
RUN cp -r /opt/nvm /home/container/ \
    && chown -R container:container /home/container/nvm

# Set the user to 'container' to run the application
USER container

# Set environment variables for user and home directory
ENV USER=container \
    HOME=/home/container \
    NVM_DIR=/home/container/nvm \
    PATH=/home/container/nvm/versions/node/v20.11.1/bin:$PATH

# Setup shell configuration for NVM
RUN echo 'export NVM_DIR="$HOME/nvm"' >> $HOME/.bashrc \
    && echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> $HOME/.bashrc \
    && echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> $HOME/.bashrc

# Set working directory to the home directory of the container
WORKDIR /home/container

# Copy the entrypoint script into the container
COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set default Node.js version
ENV NODE_VERSION=20

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 CMD [ "pgrep", "node" ]

# Default command to run the entrypoint script
CMD [ "/bin/bash", "/entrypoint.sh" ]