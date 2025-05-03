FROM node:20-bullseye

LABEL author="Nueva" \
      maintainer="admin@nueva.my.id" \
      description="A Docker image for running Node.js applications."
      

RUN apt-get update && apt-get install -y \
    python3 python3-pip python3-dev \
    php php-cli php-fpm php-common \
    ruby ruby-dev \
    golang \
    nginx \
    certbot \
    curl wget git unzip \
    lsb-release \
    gnupg \
    ca-certificates \
    fonts-liberation \
    libappindicator3-1 \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libc6 \
    libcairo2 \
    libcups2 \
    libdbus-1-3 \
    libexpat1 \
    libfontconfig1 \
    libgbm1 \
    libgcc1 \
    libglib2.0-0 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libpango-1.0-0 \
    libpangocairo-1.0-0 \
    libstdc++6 \
    libx11-6 \
    libx11-xcb1 \
    libxcb1 \
    libxcomposite1 \
    libxcursor1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxi6 \
    libxrandr2 \
    libxrender1 \
    libxss1 \
    libxtst6 \
    xdg-utils \
    ffmpeg \
    iproute2 \
    git \
    sqlite3 \
    libsqlite3-dev \
    dnsutils \
    tzdata \
    zip \
    tar \
    build-essential \
    libtool \
    iputils-ping \    
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y neofetch && apt-get clean

RUN pip3 install speedtest-cli

RUN npm install -g pm2

RUN npm install -g playwright@1.50.0 && \
    npx playwright install --with-deps

RUN useradd -m -d /home/container Nueva
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x entrypoint.sh

USER Nueva
ENV USER=Nueva HOME=/home/container
WORKDIR /home/container

ENTRYPOINT ["/entrypoint.sh"]