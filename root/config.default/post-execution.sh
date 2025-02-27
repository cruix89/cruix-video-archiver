#!/usr/bin/with-contenv bash

# directory's config
downloads_dir="/downloads"
cache_dir="/config/cache"


# remove cache files in the output directory and process post-processing scripts
if [ -d "$downloads_dir" ]; then

  sleep '5'
  mkdir -p $cache_dir
  find $cache_dir -type f -delete
  find $cache_dir -type d -empty -mindepth 1 -delete

  # post-processing scripts in downloads folder

  sleep '5'
  umask "$UMASK"
  /app/scripts/ffmpeg_encoder.sh

else
  echo -e "\e[31m\e[1m[cruix-video-archiver] oops! output directory not found: $downloads_dir\e[0m"
fi