FROM nvidia/cuda:11.7.1-runtime-ubuntu20.04

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS="2" \
    PUID="911" \
    PGID="911" \
    UMASK="022" \
    OPENSSL_CONF="" \
    DEBIAN_FRONTEND=noninteractive

# Configurar fuso horário padrão
RUN ln -fs /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime && \
    apt-get update && \
    apt-get install -y tzdata && \
    dpkg-reconfigure --frontend noninteractive tzdata

# Criar grupo e usuário
RUN set -x && \
    addgroup --gid "$PGID" abc && \
    adduser --gecos "" --disabled-password --no-create-home --uid "$PUID" --ingroup abc --shell /bin/bash abc

# Copiar arquivos
COPY root/ /

# Instalar dependências e pacotes
RUN set -x && \
    apt-get update && \
    apt-get install -y \
        file \
        wget \
        python3 \
        python3-pip \
        libc-dev \
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
        imagemagick && \
    python3 -m pip install --upgrade pip && \
    python3 -m pip --no-cache-dir install -r /app/requirements.txt && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Instalar FFMPEG com suporte a NVENC
RUN set -x && \
    apt-get update && \
    apt-get install -y ffmpeg nvidia-cuda-toolkit && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Instalar S6 overlay
RUN set -x && \
    wget -q -O /tmp/s6-overlay.tar.gz https://github.com/just-containers/s6-overlay/releases/download/v2.2.0.3/s6-overlay-amd64.tar.gz && \
    tar -xzf /tmp/s6-overlay.tar.gz -C / && \
    rm -rf /tmp/*

# Instalar yt-dlp diretamente do release do GitHub
RUN set -x && \
    wget -q -O /tmp/yt-dlp.tar.gz https://github.com/yt-dlp/yt-dlp/releases/download/2024.11.04/yt-dlp.tar.gz && \
    tar -xzf /tmp/yt-dlp.tar.gz -C /usr/local/bin && \
    chmod a+rx /usr/local/bin/yt-dlp && \
    rm -rf /tmp/*

# Definir volumes e diretório de trabalho
VOLUME /config /downloads
WORKDIR /config

# EntryPoint
ENTRYPOINT ["/init"]