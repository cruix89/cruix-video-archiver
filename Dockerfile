FROM debian:bookworm-slim

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS="2" \
    PUID="911" \
    PGID="911" \
    UMASK="022" \
    OPENSSL_CONF=""

# create group and user
RUN set -x && \
    addgroup --gid "$PGID" abc && \
    adduser --gecos "" --disabled-password --no-create-home --uid "$PUID" --ingroup abc --shell /bin/bash abc

# copy files
COPY root/ /

# install dependencies and packages (without --no-install-recommends)
RUN set -x && \
    apt-get update && \
    apt-get install -y \
        wget \
        curl \
        ca-certificates \
        python3 \
        python3-pip \
        libffi-dev \
        libgmp-dev \
        libbrotli-dev \
        gnupg && \
    python3 -m pip --no-cache-dir install -r /app/requirements.txt && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# install FFMPEG from debian repository
RUN set -x && \
    apt-get update && \
    apt-get install -y ffmpeg && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# install S6 overlay
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

# entrypoint
ENTRYPOINT ["/init"]