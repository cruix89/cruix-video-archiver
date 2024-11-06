#!/usr/bin/with-contenv bash

# environment variable configurations
normalized_log_dir="${normalized_log_dir:-/config/logs}"
normalized_list_file="${normalized_list_file:-/config/loudnorm_cache.txt}"
cache_dir="/config/cache"
failed_log_file="/config/loudnorm_failed_files_cache.txt"  # log file for failed files

# function to check if ffmpeg is installed
check_ffmpeg() {
    if ! command -v ffmpeg &> /dev/null; then
        echo "FFMPEG is not installed."
        exit 1
    fi
}

# function to load the list of normalized files
load_normalized_list() {
    if [[ ! -f "$normalized_list_file" ]]; then
        touch "$normalized_list_file"
    fi
    mapfile -t normalized_files < "$normalized_list_file"
    echo -e "\nnumber of already normalized files in cache: ${#normalized_files[@]}"
}

# function to save to the normalized list
save_to_normalized_list() {
    echo "$1" >> "$normalized_list_file"
}

# function to log a failed file
log_failed_file() {
    local src_file="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - failed processing file: $src_file" >> "$failed_log_file"
}

# function to process the video file
process_file() {
    local src_file="$1"
    local log_file="$2"
    # declare the variable
    local output_file
    # assign the value separately, removing the original extension
    output_file="${cache_dir}/$(basename "${src_file%.*}")"

    # FFMPEG command to process the file
    {
        # step 1: normalize the audio
        ffmpeg -y -threads 1 -i "$src_file" -af "loudnorm=I=-16:TP=-1:LRA=11" -vn "$output_file.wav"
        local exit_code_audio=$?

        # step 2: re-encode the video
        ffmpeg -y -threads 1 -i "$src_file" -c:v libx265 -preset slow -crf 23 -an "$output_file.mp4"
        local exit_code_video=$?

        # step 3: combine video and normalized audio
        ffmpeg -y -threads 1 -i "$output_file.mp4" -i "$output_file.wav" -c:v copy -c:a aac -strict experimental "${output_file}_x265.mp4"
        local exit_code_combine=$?

    } &>> "$log_file"

    # check the exit codes of all three stages
    if [[ -f "${output_file}_x265.mp4" && $exit_code_audio -eq 0 && $exit_code_video -eq 0 && $exit_code_combine -eq 0 ]]; then
        # delete the original file
        rm -f "$src_file"
        # move the normalized file to the original path with .mp4 extension
        mv "${output_file}_x265.mp4" "${src_file%.*}.mp4"

        save_to_normalized_list "${src_file%.*}.mp4"
        echo "processed and replaced: ${src_file%.*}.mp4"

        # clean up the cache directory after processing
        rm -f "$cache_dir"/*
        echo "cache directory cleaned: $cache_dir"
    else
        # log the failure if processing fails
        log_failed_file "$src_file"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - error processing file: $src_file" >> "$log_file"
    fi
}

# main function
main() {
    check_ffmpeg
    load_normalized_list

    local log_file="$normalized_log_dir/loudnorm.log"

    # ensure the cache directory exists
    if [[ ! -d "$cache_dir" ]]; then
        mkdir -p "$cache_dir"
        echo "created cache directory: $cache_dir"
    fi

    # find an unprocessed video file
    local src_file
    src_file=$(find "/downloads" -type f \( -name "*.mp4" -o -name "*.mkv" -o -name "*.webm" -o -name "*.flv" -o -name "*.avi" -o -name "*.mov" -o -name "*.wmv" -o -name "*.mpg" -o -name "*.mpeg" -o -name "*.3gp" -o -name "*.m4v" \) ! -exec grep -qx {} "$normalized_list_file" \; -print -quit)

    # if no unprocessed file is found, exit the script
    if [[ -z "$src_file" ]]; then
        echo -e "no unprocessed videos found. exiting.\n"
        exit 0
    fi

    # process the single unprocessed file
    process_file "$src_file" "$log_file"
}

main