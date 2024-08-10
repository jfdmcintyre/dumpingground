#!/bin/bash

# Define the URL to fetch the file list
FILE_LIST_URL="https://mirror.rcg.sfu.ca/mirror/CRAN/src/base/R-4/"

# Scan the current directory for .tar.gz files and select the one with the highest version
latest_file=""
latest_version=""

for file in R-4.*.tar.gz; do
    if [[ -f "$file" ]]; then
        # Extract version number (e.g., R-4.0.0.tar.gz)
        version=$(echo "$file" | sed -E 's/^R-4\.([0-9]+\.[0-9]+(\.[0-9]+)?)\.tar\.gz$/\1/')
        if [[ -n "$version" && ( -z "$latest_version" || "$(echo "$version" | awk -F. '{print $1$2$3}')" -gt "$(echo "$latest_version" | awk -F. '{print $1$2$3}')" ) ]]; then
            latest_file="$file"
            latest_version="$version"
        fi
    fi
done

# Check if a valid file was found
if [ -z "$latest_file" ]; then
    echo "No .tar.gz files found in the current directory."
    exit 1
fi

echo "Using the file with the highest version: $latest_file"

# Get the base name and size of the local file
file_name=$(basename "$latest_file")
file_size=$(stat -c%s "$latest_file")

# Fetch the file list from the website
temp_file=$(mktemp)
curl -s "$FILE_LIST_URL" | grep -oP '(?<=href=")[^"]+' | grep -E '^R-4\.[0-9]+(\.[0-9]+)?\.tar\.(gz|xz)$' > "$temp_file"

# Flag to indicate if the file is authentic
authentic=0

# Check each file entry for size
while IFS= read -r remote_name; do
    # Fetch file size from the server
    remote_file_url="${FILE_LIST_URL}${remote_name}"
    remote_size=$(curl -sI "$remote_file_url" | grep -i 'Content-Length' | awk '{print $2}' | tr -d '\r')

    # Check if file name matches and compare sizes
    if [ "$file_name" == "$remote_name" ] && [ "$file_size" == "$remote_size" ]; then
        authentic=1
        break
    fi
done < "$temp_file"

# Output the result based on the flag
if [ $authentic -eq 1 ]; then
    echo "The file $latest_file is authentic."
else
    echo "The file $latest_file is NOT authentic."
fi

# Clean up
rm "$temp_file"
