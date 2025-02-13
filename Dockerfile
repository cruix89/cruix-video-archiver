FROM debian:12-slim

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS="2" \
    PATH="/home/abc/.venv/bin:$PATH" \
    PUID="911" \
    PGID="911" \
    UMASK="022" \
    OPENSSL_CONF=""

# create group and user
RUN addgroup --gid "$PGID" abc && \
    adduser --gecos "" --disabled-password --uid "$PUID" --ingroup abc --shell /bin/bash abc

# copy files
COPY root/app/requirements.txt /app/

# install dependencies and packages
RUN apt update && \
    apt install -y \
        supervisor \
        file \
        wget \
        curl \
        ca-certificates \
        python3 \
        python3-venv \
        python3-pip \
        libffi-dev \
        libgmp-dev \
        libbrotli-dev \
        gnupg && \
    apt clean && \
    python3 -m venv /home/abc/.venv && \
    /home/abc/.venv/bin/pip --no-cache-dir install -r /app/requirements.txt && \
    rm -rf /var/lib/apt/lists/* /tmp/*

# copy files
COPY root/ /

# install FFMPEG from debian repository
RUN apt update && \
    apt install -y ffmpeg && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

# install S6 overlay
RUN wget -q -O /tmp/s6-overlay.tar.gz https://github.com/just-containers/s6-overlay/releases/download/v2.2.0.3/s6-overlay-amd64.tar.gz && \
    tar -xzf /tmp/s6-overlay.tar.gz -C / && \
    rm -rf /tmp/*

# install yt-dlp
RUN /home/abc/.venv/bin/pip --no-cache-dir install yt-dlp[default]

# set volumes and working directory
VOLUME /config /downloads
WORKDIR /config

# entrypoint
ENTRYPOINT ["/init"]