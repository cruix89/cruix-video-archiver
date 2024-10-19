#!/usr/bin/with-contenv bash

# environment variable configurations
normalized_log_dir="${normalized_log_dir:-/config/logs}"
normalized_list_file="${normalized_list_file:-/config/loudnorm_cache.txt}"
cache_dir="/config/cache"

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

# function to process the video file
process_file() {
    local src_file="$1"
    local log_file="$2"
    # declare the variable
    local output_file
    # assign the value separately, removing the original extension
    output_file="${cache_dir}/$(basename "${src_file%.*}")"

    # FFMPEG command to process the file
    ffmpeg -y -i "$src_file" -vf "loudnorm=I=-16:TP=-1:LRA=11:print_format=summary" -c:v libx265 -preset slow -crf 23 "$output_file.mp4" &>> "$log_file"

    # capture the exit code of ffmpeg
    local exit_code=$?

    # check if the output file exists and if the exit code is 0
    if [[ -f "$output_file.mp4" && $exit_code -eq 0 ]]; then
        # delete the original file
        rm -f "$src_file"
        # move the normalized file to the original path with .mp4 extension
        mv "$output_file.mp4" "${src_file%.*}.mp4"

        save_to_normalized_list "${src_file%.*}.mp4"
        echo "processed and replaced: ${src_file%.*}.mp4"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - error processing file: $src_file" >> "$log_file"
    fi
}

# main function
main() {
    check_ffmpeg
    load_normalized_list

    local log_file="$normalized_log_dir/loudnorm.log"
    local skipped_files=0

    # ensure the cache directory exists
    if [[ ! -d "$cache_dir" ]]; then
        mkdir -p "$cache_dir"
        echo "created cache directory: $cache_dir"
    fi

    while true; do
        # collect an unnormalized video file
        local src_file
        src_file=$(find "/downloads" -type f \( -name "*.mp4" -o -name "*.mkv" -o -name "*.webm" -o -name "*.flv" -o -name "*.avi" -o -name "*.mov" -o -name "*.wmv" -o -name "*.mpg" -o -name "*.mpeg" -o -name "*.3gp" -o -name "*.m4v" \) ! -exec grep -qx {} "$normalized_list_file" \; -print -quit)

        # if there are no more files to process, exit the loop
        if [[ -z "$src_file" ]]; then
            break
        fi

        # check if the file was skipped
        if grep -qx "$src_file" "$normalized_list_file"; then
            ((skipped_files++))
            echo "skipped: $src_file"
            continue
        fi

        process_file "$src_file" "$log_file"
    done

    # final summary
    echo "all files have been processed and normalized successfully."
}

main