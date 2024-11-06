# Base image com CUDA e Ubuntu 20.04
FROM nvidia/cuda:11.7.1-runtime-ubuntu20.04

# Definir variáveis de ambiente
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS="2" \
    PUID="911" \
    PGID="911" \
    UMASK="022" \
    OPENSSL_CONF=""

# Instalar dependências necessárias para adicionar repositórios e instalar o Python
RUN set -x && \
    apt-get update && \
    apt-get install -y \
    software-properties-common \
    wget \
    curl \
    gnupg2 && \
    add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update

# Instalar a versão mais recente do Python (exemplo: Python 3.11)
RUN set -x && \
    apt-get install -y python3.11 python3.11-dev python3.11-distutils && \
    ln -sf /usr/bin/python3.11 /usr/bin/python3 && \
    python3 --version  # Verificar a versão do Python

# Instalar o pip para Python 3.11
RUN set -x && \
    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && \
    python3 get-pip.py && \
    rm get-pip.py

# Instalar o yt-dlp usando pip
RUN set -x && \
    python3 -m pip install --no-cache-dir yt-dlp==2024.11.04

# Criar grupo e usuário
RUN set -x && \
    addgroup --gid "$PGID" abc && \
    adduser --gecos "" --disabled-password --no-create-home --uid "$PUID" --ingroup abc --shell /bin/bash abc

# Copiar arquivos para o container
COPY root/ /

# Instalar dependências e pacotes adicionais
RUN set -x && \
    apt-get update && \
    apt-get install -y \
    file \
    libc-dev \
    xvfb \
    scrot \
    xclip \
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
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Instalar FFMPEG com suporte a NVENC
RUN set -x && \
    apt-get update && \
    apt-get install -y \
    ffmpeg \
    nvidia-cuda-toolkit \
    nvidia-smi \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Verificar se o FFMPEG tem suporte a NVENC
RUN set -x && \
    ffmpeg -encoders | grep nvenc

# Instalar S6 overlay
RUN set -x && \
    wget -q -O /tmp/s6-overlay.tar.gz https://github.com/just-containers/s6-overlay/releases/download/v2.2.0.3/s6-overlay-amd64.tar.gz && \
    tar -xzf /tmp/s6-overlay.tar.gz -C / && \
    rm -rf /tmp/*

# Configurar volumes e diretório de trabalho
VOLUME /config /downloads
WORKDIR /config

# Entrypoint
ENTRYPOINT ["/init"]