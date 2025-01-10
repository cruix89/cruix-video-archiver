#!/usr/bin/with-contenv bash

# enforce utf-8 encoding
export LANG="C.UTF-8"
export LC_ALL="C.UTF-8"

# environment variable configurations
normalized_log_dir="${normalized_log_dir:-/config/logs}"
normalized_list_file="${normalized_list_file:-/config/ffmpeg_cache.txt}"
cache_dir="/config/cache"
failed_log_file="/config/ffmpeg_failed_files_cache.txt"  # log file for failed files

# function to check if ffmpeg is installed
check_ffmpeg() {
    if ! command -v ffmpeg &> /dev/null; then
        echo -e "[cruix-video-archiver] FFMPEG is Not Installed. The Force is Weak in This System, No Media Manipulation Powers!"
        exit 1
    fi
}

# function to load the list of normalized files
load_normalized_list() {
    if [[ ! -f "$normalized_list_file" ]]; then
        touch "$normalized_list_file"
    fi
    mapfile -t normalized_files < "$normalized_list_file"
    echo -e "[cruix-video-archiver] Number of Normalized Files In Cache: ${#normalized_files[@]} - Cache is Grooving!"
}

# function to save to the normalized list
save_to_normalized_list() {
    echo "$1" >> "$normalized_list_file"
}

# function to log a failed file
log_failed_file() {
    local src_file="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Failed Processing File: $src_file" >> "$failed_log_file"
}

# function to process the video file with real-time progress display
process_file() {
    local src_file="$1"
    local log_file="$2"
    local output_file
    output_file="${cache_dir}/$(basename "${src_file%.*}")"

    # FFMPEG command to normalize audio, re-encode video, and combine
    {
        # step 1: normalize the audio
        echo -e "\033[1;32m[cruix-video-archiver] Starting Audio Normalization For: $src_file . Because Even Your Files Deserve To Hit The Right Notes!\033[0m\n"
        sleep 15
        ffmpeg -y -i "$src_file" -af "loudnorm=I=-16:TP=-1:LRA=11" -vn "$output_file.wav" | tee -a "$log_file"
        local exit_code_audio=$?

        # step 2: re-encode the video
        echo -e "\033[1;32m[cruix-video-archiver] Starting Video Re-Encoding For: $src_file . The HVEC transformation is in action!\033[0m\n"
        sleep 15
        ffmpeg -y -i "$src_file" -c:v libx265 -preset slow -crf 23 -an "$output_file.mp4" | tee -a "$log_file"
        local exit_code_video=$?

        # step 3: combine video and normalized audio
        echo -e "\033[1;32m[cruix-video-archiver] Merging Video and Audio For: $src_file . Crafting the Perfect Symphony!\033[0m\n"
        sleep 15
        ffmpeg -y -i "$output_file.mp4" -i "$output_file.wav" -c:v copy -c:a aac -strict experimental "${output_file}_x265.mp4" | tee -a "$log_file"
        local exit_code_combine=$?

    }

    # check the exit codes of all three stages
    if [[ -f "${output_file}_x265.mp4" && $exit_code_audio -eq 0 && $exit_code_video -eq 0 && $exit_code_combine -eq 0 ]]; then
        rm -f "$src_file"
        mv "${output_file}_x265.mp4" "${src_file%.*}.mp4"
        save_to_normalized_list "${src_file%.*}.mp4"
        echo -e "[cruix-video-archiver] Processed and Replaced: ${src_file%.*}.mp4 "
        rm -f "$cache_dir"/*
        echo -e "[cruix-video-archiver] Cleaning Cache Directory: $cache_dir "
    else
        log_failed_file "$src_file"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Error Processing File: $src_file" >> "$log_file"
    fi
}

# main function
main() {
    check_ffmpeg
    load_normalized_list

    local log_file="$normalized_log_dir/ffmpeg_encoder.log"

    # ensure the cache directory exists
    if [[ ! -d "$cache_dir" ]]; then
        mkdir -p "$cache_dir"
        echo "[cruix-video-archiver] Created Cache Directory: $cache_dir "
    fi

    # find an unprocessed video file
    local src_file
    src_file=$(find "/downloads" -type f \( -name "*.mp4" -o -name "*.mkv" -o -name "*.webm" -o -name "*.flv" -o -name "*.avi" -o -name "*.mov" -o -name "*.wmv" -o -name "*.mpg" -o -name "*.mpeg" -o -name "*.3gp" -o -name "*.m4v" \) ! -exec grep -F -x -q "{}" "$normalized_list_file" \; -print -quit)

    # if no unprocessed file is found, exit the script
    if [[ -z "$src_file" ]]; then
        echo -e "[cruix-video-archiver] No Unprocessed Videos Found. Exiting."
        exit 0
    fi

    # process the single unprocessed file
    process_file "$src_file" "$log_file"
}

main