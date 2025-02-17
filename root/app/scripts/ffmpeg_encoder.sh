#!/usr/bin/with-contenv bash

# enforce utf-8 encoding
export LANG="C.UTF-8"
export LC_ALL="C.UTF-8"

# environment variable configurations
normalized_list_file="${normalized_list_file:-/config/ffmpeg_cache.txt}"
cache_dir="/config/cache"
failed_log_file="/config/ffmpeg_failed_files_cache.txt"

# function to check if ffmpeg is installed
check_ffmpeg() {
    if ! command -v ffmpeg &> /dev/null; then
        echo -e "\e[31m\e[1m[cruix-video-archiver] error: ffmpeg not found.\e[0m"
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
    echo "$1" >> "$failed_log_file"
}

# function to wait for file release
wait_for_file_release() {
    local file="$1"
    while lsof "$file" &> /dev/null; do
        echo -e "\e[33m\e[1m[cruix-video-archiver] waiting for file to be released: $file\e[0m"
        sleep 5
    done
}

# function to process the video file
process_file() {
    local src_file="$1"
    local output_file

    output_file="${cache_dir}/$(basename "${src_file%.*}.mkv")"

    echo -e "\e[32m\e[1m[cruix-video-archiver] processing: $src_file\e[0m"

    ffmpeg -y -i "$src_file" -map 0 -c:v copy -c:s copy -c:a pcm_s16le -af "loudnorm=I=-14:TP=-1:LRA=8" -loglevel verbose -stats "temp_audio.wav" && \
    ffmpeg -y -i "$src_file" -i "temp_audio.wav" -map 0:v -map 1:a -map 0:s? -c:v copy -c:a aac -b:a 320k -c:s copy "$output_file" && \
    rm "temp_audio.wav"
    local exit_code=$?

    sync

    if [[ -f "$output_file" && $exit_code -eq 0 ]]; then
        echo -e "\e[32m\e[1m[cruix-video-archiver] successfully processed: $output_file\e[0m"
        sleep 5
        wait_for_file_release "$src_file"
        rm -f "$src_file"
        mv "$output_file" "${src_file%.*}.mkv"
        save_to_normalized_list "${src_file%.*}.mkv"
        find "$cache_dir" -type f -delete
        echo -e "\e[32m\e[1m[cruix-video-archiver] cache cleaned.\e[0m"
    else
        log_failed_file "$src_file"
        echo -e "\e[31m\e[1m[cruix-video-archiver] error: process failed for: $src_file\e[0m"
    fi
}

# main function
main() {
    check_ffmpeg
    load_normalized_list

    if [[ ! -d "$cache_dir" ]]; then
        mkdir -p "$cache_dir"
    fi

    local src_file
    src_file=$(find "/downloads" -type f \( -name "*.mp4" -o -name "*.mkv" -o -name "*.webm" -o -name "*.flv" -o -name "*.avi" -o -name "*.mov" -o -name "*.wmv" -o -name "*.mpg" -o -name "*.mpeg" -o -name "*.3gp" -o -name "*.m4v" \) \
        | while read -r file; do
            if ! grep -Fxq "$file" "$normalized_list_file"; then
                echo "$file"
            fi
        done | head -n 1)

    if [[ -z "$src_file" ]]; then
        echo -e "\e[32m\e[1m[cruix-video-archiver] no unprocessed videos found.\e[0m"
        exit 0
    fi

    process_file "$src_file"
}

main