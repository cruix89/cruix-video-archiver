#!/usr/bin/with-contenv bash

# directory's config
downloads_dir="/downloads"
cache_dir="/config/cache"
logs_dir="/config/logs"

# remove cache files in the output directory and process post-processing scripts
if [ -d "$downloads_dir" ]; then

  echo -e "\ncleaning cache files in directory's: /cache /logs /downloads"

  sleep '5'
  mkdir -p $cache_dir
  find $cache_dir -type f -delete
  find $cache_dir -type d -empty -mindepth 1 -delete

  sleep '5'
  find "$downloads_dir" -mindepth 1 -type d -empty -delete

  echo -e "executing post-processing scripts for the video library normalization"

  # post-processing scripts in downloads folder

  sleep '5'
  mkdir -p $logs_dir
  find $logs_dir -type f -delete

  sleep '5'
  umask "$UMASK"
  /app/extended-scripts/loudnorm.sh

  sleep '5'
  find "$downloads_dir" -mindepth 1 -type d -empty -delete

else
  echo -e "\noutput directory not found: $downloads_dir"
fi