# Multi-stage build untuk lingkungan Node.js yang optimal
FROM ubuntu:22.04 AS base

# Metadata
LABEL author="nueva" \
      maintainer="admin@nueva.my.id" \
      description="Optimized Docker image for Nueva Developer Panel with Node.js, PM2, and essential tools" \
      version="2.0" \
      repository="https://github.com/nueeva/egg" \
      branch="main"

# Environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=UTC \
    LANGUAGE=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    NODE_ENV=production

# Update system dan install dependencies
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y \
    # Core utilities
    curl wget gnupg git unzip zip tar \
    # Build tools
    build-essential pkg-config python3 python3-dev python3-pip \
    # Network tools
    iputils-ping dnsutils net-tools iproute2 netcat-openbsd \
    # System utilities
    locales tzdata ca-certificates sudo \
    # Database support
    sqlite3 libsqlite3-dev \
    # Media processing
    ffmpeg imagemagick \
    # Text processing and utilities
    jq vim nano htop procps lsof \
    # Clean up
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Configure locale
RUN locale-gen en_US.UTF-8

# Create container user dengan sudo privileges
RUN useradd -m -d /home/container -s /bin/bash container && \
    echo "container ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/container && \
    mkdir -p /home/container && \
    chown -R container:container /home/container

# Install Node.js via NodeSource repository untuk stabilitas yang lebih baik
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs

# Install global npm packages
RUN npm install -g npm@latest pm2@latest yarn@latest pnpm@latest

# Install NVM untuk version management
ENV NVM_DIR=/usr/local/nvm
RUN mkdir -p $NVM_DIR && \
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash && \
    . $NVM_DIR/nvm.sh && \
    nvm install 18 && \
    nvm install 20 && \
    nvm install 22 && \
    nvm alias default 20

# Copy NVM ke container user home
RUN cp -R $NVM_DIR /home/container/nvm && \
    chown -R container:container /home/container/nvm

# Switch ke container user
USER container
WORKDIR /home/container

# Configure bash environment untuk container user
RUN echo 'export NVM_DIR="/home/container/nvm"' >> /home/container/.bashrc && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> /home/container/.bashrc && \
    echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> /home/container/.bashrc && \
    echo 'export PATH="$NVM_DIR/versions/node/$(nvm version default)/bin:$PATH"' >> /home/container/.bashrc

# Copy entrypoint script dari GitHub repository
COPY ./entrypoint.sh /entrypoint.sh

# Set final environment variables
ENV USER=container \
    HOME=/home/container \
    NVM_DIR=/home/container/nvm

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD node --version && pm2 --version || exit 1

# Expose common ports
EXPOSE 3000 8000 8080 5000 4000

# Set entrypoint
CMD ["/bin/bash", "/entrypoint.sh"]
