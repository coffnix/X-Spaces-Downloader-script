#!/usr/bin/env bash

#
# Twitter/X Space Downloader Bash Script
# Copyright (c) 2024 Rodrigo Polo - rodrigopolo.com - The MIT License (MIT)
#

# Check required commands
for cmd in yt-dlp wget aria2c ffmpeg grep sed; do
	if ! command -v "$cmd" >/dev/null 2>&1; then
		echo "Required command not found: $cmd"
		exit 1
	fi
done

# Check if a stream URL is provided
if [ -z "$1" ]; then
	echo "Usage: $0 <stream_url>"
	exit 1
fi

# Modifying the internal field separator
IFS=$'\t\n'

SPACEURL="$1"

STREAM="$(yt-dlp --cookies-from-browser opera -g "$SPACEURL")"
if [ -z "$STREAM" ]; then
	echo "Failed to get stream URL."
	exit 1
fi

FILE_NAME="$(yt-dlp --cookies-from-browser opera --get-filename -o "%(upload_date)s - %(uploader_id)s.%(title)s.%(id)s.%(ext)s" "$SPACEURL")"
if [ -z "$FILE_NAME" ]; then
	echo "Failed to get output filename."
	exit 1
fi

# Get the stream path
STREAMPATH="$(printf '%s\n' "$STREAM" | grep -Eo '(^.*[\/])')"
if [ -z "$STREAMPATH" ]; then
	echo "Failed to determine stream base path."
	exit 1
fi

# Download the stream
if ! wget "$STREAM" -O stream.m3u8; then
	echo "Failed to download the stream."
	exit 1
fi

# Prefix the URLs for the chunks
if ! sed -E "s|(^[^.#]+\.aac$)|${STREAMPATH}\1|g" stream.m3u8 > modified.m3u8; then
	echo "Failed to generate modified playlist."
	exit 1
fi

# Download the chunks
if ! aria2c -x 10 --console-log-level warn -i modified.m3u8; then
	echo "Failed to download audio chunks."
	exit 1
fi

# Join the chunks
if ! ffmpeg -i stream.m3u8 -vn -acodec copy -movflags +faststart "$FILE_NAME"; then
	echo "Failed to join audio chunks."
	exit 1
fi

# Clean-up temporary files
grep -Eo '(^[^.#]+\.aac$)' stream.m3u8 | while IFS= read -r chunk; do
	rm -f -- "$chunk"
done

rm -f stream.m3u8 modified.m3u8
