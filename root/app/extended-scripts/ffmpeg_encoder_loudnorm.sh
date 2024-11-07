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
    local file_to_save
    file_to_save="$1"
    echo "$file_to_save" >> "$normalized_list_file"
}

# function to log a failed file
log_failed_file() {
    local src_file
    src_file="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - failed processing file: $src_file" >> "$failed_log_file"
}

# function to monitor log for progress
monitor_log() {
    local log_file
    log_file="$1"
    declare -A printed_lines

    while true; do
        while read -r line; do
            if [[ "$line" == *"frame="* ]]; then
                if [[ -z "${printed_lines["$line"]}" ]]; then
                    echo "$line"
                    printed_lines["$line"]=1
                fi
            fi
        done < "$log_file"
        sleep 1
    done
}

# function to process the video file
process_file() {
    local src_file log_file output_file pid_audio
    src_file="$1"
    log_file="$2"
    output_file="${cache_dir}/$(basename "${src_file%.*}")"

    # Create temporary files for exit codes
    local exit_code_audio_file="/tmp/exit_code_audio_$RANDOM"
    local exit_code_combine_file="/tmp/exit_code_combine_$RANDOM"

    # Run ffmpeg in background to normalize audio and re-encode video
    {
        ffmpeg -y -i "$src_file" -af "loudnorm=I=-16:TP=-1:LRA=11" -vn "$output_file.wav"
        echo $? > "$exit_code_audio_file"

        ffmpeg -y -i "$src_file" -c:v libx265 -preset slow -crf 23 -an "$output_file.mp4"
        echo $? > "$exit_code_combine_file"

        ffmpeg -y -i "$output_file.mp4" -i "$output_file.wav" -c:v copy -c:a aac -strict experimental "${output_file}_x265.mp4"
        echo $? > "$exit_code_combine_file"
    } &>> "$log_file" &

    # Capture the ffmpeg PID and start monitoring the log file
    pid_audio=$!
    monitor_log "$log_file" &
    local monitor_pid
    monitor_pid=$!

    # Wait for ffmpeg to finish
    wait "$pid_audio"

    # Retrieve exit codes from temporary files
    local exit_code_audio
    exit_code_audio=$(<"$exit_code_audio_file")
    local exit_code_combine
    exit_code_combine=$(<"$exit_code_combine_file")

    # Kill the monitor after ffmpeg completes
    kill "$monitor_pid" &>/dev/null

    # Clean up the temporary files
    rm "$exit_code_audio_file" "$exit_code_combine_file"

    # Check ffmpeg exit status and cleanup or log failure
    if [[ $exit_code_audio -eq 0 && $exit_code_combine -eq 0 && -f "${output_file}_x265.mp4" ]]; then
        rm -f "$src_file"
        mv "${output_file}_x265.mp4" "${src_file%.*}.mp4"
        save_to_normalized_list "${src_file%.*}.mp4"
        echo "processed and replaced: ${src_file%.*}.mp4"
        rm -f "$cache_dir"/*
        echo -e "\ncache directory cleaned: $cache_dir"
    else
        log_failed_file "$src_file"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - error processing file: $src_file" >> "$log_file"
    fi
}

# main function
main() {
    check_ffmpeg
    load_normalized_list

    local log_file src_file
    log_file="$normalized_log_dir/ffmpeg_encoder_loudnorm.log"

    # ensure the cache directory exists
    if [[ ! -d "$cache_dir" ]]; then
        mkdir -p "$cache_dir"
        echo "created cache directory: $cache_dir"
    fi

    # find an unprocessed video file
    src_file=$(find "/downloads" -type f \( -name "*.mp4" -o -name "*.mkv" -o -name "*.webm" -o -name "*.flv" -o -name "*.avi" -o -name "*.mov" -o -name "*.wmv" -o -name "*.mpg" -o -name "*.mpeg" -o -name "*.3gp" -o -name "*.m4v" \) ! -exec grep -qx {} "$normalized_list_file" \; -print -quit)

    if [[ -z "$src_file" ]]; then
        echo -e "no unprocessed videos found. exiting.\n"
        exit 0
    fi

    process_file "$src_file" "$log_file"
}

main