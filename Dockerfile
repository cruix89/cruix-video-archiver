FROM debian:11-slim

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS="2" \
    PUID="911" \
    PGID="911" \
    UMASK="022" \
    OPENSSL_CONF=""

# configure the official debian mirror
RUN set -x && \
    echo "deb http://deb.debian.org/debian stable main contrib non-free" > /etc/apt/sources.list && \
    echo "deb http://security.debian.org/debian-security stable-security main contrib non-free" >> /etc/apt/sources.list && \
    apt-get update

# create group and user
RUN set -x && \
    addgroup --gid "$PGID" abc && \
    adduser --gecos "" --disabled-password --no-create-home --uid "$PUID" --ingroup abc --shell /bin/bash abc

# copy files
COPY root/ /

# install dependencies and packages
RUN set -x && \
    apt-get upgrade -y && \
    apt-get install -y \
        file \
        wget \
        python3 \
        python3-pip \
        libc6-dev \
        xvfb \
        scrot \
        xclip \
        curl \
        ca-certificates \
        fonts-liberation \
        libappindicator3-1 \
        libasound2 \
        libatk-bridge2.0-0 \
        libnspr4 \
        libnss3 \
        libxcomposite1 \
        libxdamage1 \
        libxrandr2 \
        xdg-utils \
        gnupg \
        libjpeg-dev \
        zlib1g-dev \
        libfreetype6-dev \
        libpng-dev \
        libtiff-dev \
        ghostscript \
        liblcms2-dev \
        libfontconfig1-dev \
        libffi-dev \
        libxml2-dev \
        libgdk-pixbuf2.0-dev \
        libglib2.0-dev \
        libmagickwand-dev \
        imagemagick-common \
        imagemagick && \
    python3 -m pip --no-cache-dir install --upgrade pip && \
    python3 -m pip --no-cache-dir install -r /app/requirements.txt && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# install ffmpeg from the official debian repository
RUN set -x && \
    apt-get update && \
    apt-get install -y ffmpeg && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# install s6 overlay
RUN set -x && \
    wget -q -O /tmp/s6-overlay.tar.gz https://github.com/just-containers/s6-overlay/releases/download/v2.2.0.3/s6-overlay-amd64.tar.gz && \
    tar -xzf /tmp/s6-overlay.tar.gz -C / && \
    rm -rf /tmp/*

# install yt-dlp
RUN set -x && \
    python3 -m pip --no-cache-dir install yt-dlp

# set volumes and working directory
VOLUME /config /downloads
WORKDIR /config

# set entrypoint
ENTRYPOINT ["/init"]