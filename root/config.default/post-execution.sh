#!/usr/bin/with-contenv bash

# directory's config
downloads_dir="/downloads"
cache_dir="/config/cache"
logs_dir="/config/logs"


# remove cache files in the output directory and process post-processing scripts
if [ -d "$downloads_dir" ]; then

  echo -e "[cruix-video-archiver] Initiating Cleanup Protocol... Purging Cache Files From the Following Directories: /cache and /logs"

  sleep '5'
  mkdir -p $cache_dir
  find $cache_dir -type f -delete
  find $cache_dir -type d -empty -mindepth 1 -delete

  echo -e "[cruix-video-archiver] Executing FFMPEG Process In The Video Library..."

  # post-processing scripts in downloads folder

  sleep '5'
  mkdir -p $logs_dir
  find $logs_dir -type f -delete

  sleep '5'
  umask "$UMASK"
  /app/scripts/ffmpeg_encoder.sh

else
  echo -e "[cruix-video-archiver] Oops! Output Directory Not Found: $downloads_dir "
fi