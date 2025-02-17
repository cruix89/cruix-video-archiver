#!/usr/bin/with-contenv bash

echo -e "\033[1;35m[cruix-video-archiver] updating yt-dlp...\033[0m"
touch '/tmp/updater-running'; sleep 1m
pip3 --no-cache-dir install --upgrade --break-system-packages yt-dlp 2>&1 | grep -v "WARNING: Running pip as the 'root'"
rm -f '/tmp/updater-running'
echo -e "\033[1;35m[cruix-video-archiver] yt-dlp is up to date.\033[0m"