#!/usr/bin/with-contenv bash

# enforce utf-8 encoding
export LANG="C.UTF-8"
export LC_ALL="C.UTF-8"

# get container user permissions
PUID=${PUID:-1000}
PGID=${PGID:-100}
UMASK=${UMASK:-000}

# group create
if ! getent group "$PGID" >/dev/null 2>&1; then
    groupadd -g "$PGID" containergroup
fi

# user create
if ! id "$PUID" >/dev/null 2>&1; then
    useradd -u "$PUID" -g "$PGID" -m containeruser
fi

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

# function to check if ffprobe is installed
check_ffprobe() {
    if ! command -v ffprobe &> /dev/null; then
        echo -e "\e[31m\e[1m[cruix-video-archiver] error: ffprobe not found.\e[0m"
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
    local file="$1"
    echo "$file" >> "$normalized_list_file"
}

# function to log a failed file
log_failed_file() {
    local file="$1"
    echo "$file" >> "$failed_log_file"
}

# function to wait for file release
wait_for_file_release() {
    local file="$1"
    while lsof "$file" &> /dev/null; do
        echo -e "\e[32m\e[1m[cruix-video-archiver] waiting for file to be released: $file\e[0m"
        sleep 5
    done
}

# function to process the video file
process_file() {
    local src_file="$1"
    local output_file
    output_file="$cache_dir/$(basename "${src_file%.*}.mkv")"

    echo -e "\e[32m\e[1m[cruix-video-archiver] starting ffmpeg normalization process in: \"$src_file\"\e[0m"

    # extract video track
    ffmpeg -y -loglevel info -i "$src_file" -map 0:v:0 -c:v copy "$cache_dir/video_track.mp4"
    echo -e "\e[32m\e[1m[cruix-video-archiver] video tracks extracted successfully: 1\e[0m"

    # detect the number of subtitle tracks
    local index_subtitle_tracks
    local subtitle_tracks
    subtitle_tracks=$(ffprobe -v error -select_streams s -show_entries stream=index -of csv=p=0 "$src_file" | wc -l)

    echo -e "\e[32m\e[1m[cruix-video-archiver] subtitle tracks detected: $subtitle_tracks, starting extraction process...\e[0m"

    # iterate over subtitle tracks
    for ((index_subtitle_tracks = 0; index_subtitle_tracks < subtitle_tracks; index_subtitle_tracks++)); do
        if ffprobe -v error -select_streams s:$index_subtitle_tracks -show_entries stream=index -of default=noprint_wrappers=1 "$src_file"; then
            ffmpeg -y -loglevel info -i "$src_file" -map 0:s:$index_subtitle_tracks -c:s copy "$cache_dir/subtitle_tracks_${index_subtitle_tracks}.srt"
        else
            break  # if there are no more subtitle tracks, exit the loop
        fi
    done

    # extract all audio tracks separately using ffprobe
    local map_audio=""
    local index
    local audio_tracks
    audio_tracks=$(ffprobe -v error -select_streams a -show_entries stream=index -of csv=p=0 "$src_file" | wc -l)

    echo -e "\e[32m\e[1m[cruix-video-archiver] audio tracks detected: $audio_tracks, starting extraction process...\e[0m"

    # iterate over audio tracks
    for ((index = 0; index < audio_tracks; index++)); do
        if ffprobe -v error -select_streams a:$index -show_entries stream=index -of default=noprint_wrappers=1 "$src_file"; then
            # extract audio in original format, convert to AAC
            ffmpeg -y -loglevel info -i "$src_file" -map 0:a:$index -c:a aac -b:a 320k -ac 2 -profile:a aac_low "$cache_dir/audio_${index}.aac"
            map_audio+=" -i \"$cache_dir/audio_${index}.aac\""
        else
            break  # no more audio tracks
        fi
    done

    # normalize each audio track with loudnorm
    for file in "$cache_dir"/audio_*.aac; do
        echo -e "\e[32m\e[1m[cruix-video-archiver] starting audio tracks loudness normalization process...\e[0m"
        ffmpeg -y -loglevel debug -i "$file" -af "loudnorm=I=-14:TP=-1:LRA=11:print_format=summary" -c:a aac -b:a 320k -ac 2 -profile:a aac_low "${file%.aac}_norm.aac"
        mv "${file%.aac}_norm.aac" "$file"  # replace original file with normalized version
    done

    # reassemble the MKV with mkvmerge
    echo -e "\e[32m\e[1m[cruix-video-archiver] starting mkv packaging process...\e[0m"
    local mkvmerge_command
    mkvmerge_command="mkvmerge -o \"$output_file\" --video-tracks 0 \"$cache_dir/video_track.mp4\""

    # add subtitle tracks to mkvmerge command only if they exist
    mapfile -d '' subtitle_tracks < <(find "$cache_dir" -maxdepth 1 -type f -name "subtitle_tracks_*.srt" -print0)

    if [[ ${#subtitle_tracks[@]} -gt 0 ]]; then
        for subtitle in "${subtitle_tracks[@]}"; do
            mkvmerge_command+=" --subtitle-tracks 0 \"$subtitle\""
        done
    fi

    # add audio tracks to mkvmerge command
    for file in "$cache_dir"/audio_*.aac; do
        mkvmerge_command+=" --audio-tracks 0 \"$file\""
    done

    echo -e "\e[32m\e[1m[cruix-video-archiver] mkvmerge: $mkvmerge_command\e[0m"

    eval "$mkvmerge_command"

    local exit_code=$?
    sync

    if [[ -f "$output_file" && $exit_code -eq 0 ]]; then
        echo -e "\e[32m\e[1m[cruix-video-archiver] successfully processed: $output_file... exiting\e[0m"

        sleep 5
        wait_for_file_release "$src_file"
        rm -f "$src_file"
        mv "$output_file" "${src_file%.*}.mkv"
        save_to_normalized_list "${src_file%.*}.mkv"

        find "$cache_dir" -type f -delete

    else
        log_failed_file "$src_file"
        echo -e "\e[31m\e[1m[cruix-video-archiver] error: process failed for: \"$src_file\"... exiting\e[0m"
    fi
}

# main function
main() {
    check_ffmpeg
    check_ffprobe
    load_normalized_list

    if [[ ! -d "$cache_dir" ]]; then
        mkdir -p "$cache_dir"
    fi

    local src_file
    src_file=$(find "/downloads" -type f \( -name "*.mp4" -o -name "*.mkv" -o -name "*.webm" -o -name "*.flv" -o -name "*.avi" -o -name "*.mov" -o -name "*.wmv" -o -name "*.mpg" -o -name "*.mpeg" -o -name "*.3gp" -o -name "*.m4v" \) \
        | while read -r file; do
            if ! grep -Fxq "$file" "$normalized_list_file"; then
                echo "$file" 2>/dev/null
            fi
        done | head -n 1)

    if [[ -z "$src_file" ]]; then
        echo -e "\e[32m\e[1m[cruix-video-archiver] no unprocessed videos found.... exiting\e[0m"
        exit 0
    fi

    process_file "$src_file"
}

main