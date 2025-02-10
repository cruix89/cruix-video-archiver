#!/usr/bin/with-contenv bash

# enforce utf-8 encoding
export LANG="C.UTF-8"
export LC_ALL="C.UTF-8"

# environment variable configurations
normalized_log_dir="${normalized_log_dir:-/config/logs}"
normalized_list_file="${normalized_list_file:-/config/ffmpeg_cache.txt}"
cache_dir="/config/cache"
failed_log_file="/config/ffmpeg_failed_files_cache.txt"

# function to check if ffmpeg is installed
check_ffmpeg() {
    if ! command -v ffmpeg &> /dev/null; then
        echo "[cruix-video-archiver] ERROR: FFMPEG Not Found."
        exit 1
    fi
}

# function to load the list of normalized files
load_normalized_list() {
    if [[ ! -f "$normalized_list_file" ]]; then
        touch "$normalized_list_file"
    fi
}

# function to save to the normalized list
save_to_normalized_list() {
    echo "$1" >> "$normalized_list_file"
}

# function to log a failed file
log_failed_file() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Failed Processing File: $1" >> "$failed_log_file"
}

# function to wait for file release
wait_for_file_release() {
    local file="$1"
    while lsof "$file" &> /dev/null; do
        echo "[cruix-video-archiver] Waiting for File to be Released: $file"
        sleep 5
    done
}

# function to process the video file with real-time progress display
process_file() {
    local src_file="$1"
    local log_file="$2"

    # declare the variable output_file first
    local output_file

    # assign the value to output_file separately
    output_file="${cache_dir}/$(basename "${src_file%.*}.mkv")"

    echo "[cruix-video-archiver] Processing: $src_file"

    # normalize all audio tracks and keep everything else unchanged
    ffmpeg -y -i "$src_file" -map 0 -c:v copy -c:s copy -c:a aac -af "loudnorm=I=-14:TP=-1:LRA=8" "$output_file" >> "$log_file" 2>&1
    local exit_code
    exit_code=$?

    # ensure ffmpeg finished writing before proceeding
    sync

    # check if the process was successful
    if [[ -f "$output_file" && $exit_code -eq 0 ]]; then
        echo "[cruix-video-archiver] Successfully Processed: $output_file"

        # wait for file system to stabilize
        sleep 5

        # ensure file is not in use before proceeding
        wait_for_file_release "$src_file"

        # remove original and move processed file only if ffmpeg has finished successfully
        if [[ -f "$output_file" && ! -f "$src_file" ]]; then
            rm -f "$src_file"
            mv "$output_file" "${src_file%.*}.mkv"

            # register in cache only after successful move
            save_to_normalized_list "${src_file%.*}.mkv"

            # clean cache
            find "$cache_dir" -type f -delete
            echo "[cruix-video-archiver] Cache Cleaned."
        else
            log_failed_file "$src_file"
            echo "[cruix-video-archiver] ERROR: Processing Failed For: $src_file"
        fi
    else
        log_failed_file "$src_file"
        echo "[cruix-video-archiver] ERROR: Processing Failed For: $src_file"
    fi
}

# main function
main() {
    check_ffmpeg
    load_normalized_list

    local log_file="$normalized_log_dir/ffmpeg_encoder.log"

    if [[ ! -d "$cache_dir" ]]; then
        mkdir -p "$cache_dir"
    fi

    # declare the variable first
    local src_file

    # now assign the result of find to src_file
    src_file=$(find "/downloads" -type f \( -name "*.mp4" -o -name "*.mkv" -o -name "*.webm" -o -name "*.flv" -o -name "*.avi" -o -name "*.mov" -o -name "*.wmv" -o -name "*.mpg" -o -name "*.mpeg" -o -name "*.3gp" -o -name "*.m4v" \) \
        | while read -r file; do
            if ! grep -Fxq "$(basename "$file")" "$normalized_list_file"; then
                echo "$file"
            fi
        done | head -n 1)

    # if no unprocessed video is found, exit
    if [[ -z "$src_file" ]]; then
        echo "[cruix-video-archiver] No Unprocessed Videos Found."
        exit 0
    fi

    # process the found video file
    process_file "$src_file" "$log_file"
}

main