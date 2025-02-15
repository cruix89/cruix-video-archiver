#!/usr/bin/with-contenv bash

touch '/tmp/updater-running'; sleep 1m
pip3 --no-cache-dir install --upgrade --break-system-packages yt-dlp
rm -f '/tmp/updater-running'
sleep 3h