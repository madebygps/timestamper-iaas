#!/bin/bash

output_dir='/volume1/shared-mount/extracted_audio'

# check if parameter exist
if [ $# -ne 1 ]; then
    echo "Usage: $0 <input_file>"
    exit 1
fi

filename=$(basename "$1")
filenamenoext="${filename%.mp4}"

mkdir -p "$output_dir"

ffmpeg -i "$1" -vn -acodec mp3 "$output_dir/${filenamenoext}.mp3"

