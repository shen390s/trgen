#!/bin/sh

binary="$1"
dir="$2"

if [ -z "$binary" ]; then
    echo "Usage: $0 binary_file_with_debug_info [generate_dir]"
    exit 1
fi

