#!/bin/bash

# Define the URL to fetch the file list
FILE_LIST_URL="https://mirror.rcg.sfu.ca/mirror/CRAN/src/base/R-4/"
LOCAL_TAR_FILE="$1"

# Check if a local tar file is provided
if [ -z "$LOCAL_TAR_FILE" ]; then
    echo "Usage: $0 <local_tar_file>"
    exit 1
fi

# Check if the local file exists
if [ ! -f "$LOCAL_TAR_FILE" ]; then
    echo "File $LOCAL_TAR_FILE does not exist."
    exit 1
fi

# Get the base name and size of the local file
file_name=$(basename "$LOCAL_TAR_FILE")
file_size=$(stat -c%s "$LOCAL_TAR_FILE")

echo "Local file: $file_name"
echo "Local size: $file_size"

# Function to show a spinner while waiting
show_spinner() {
    local pid=$1
    local delay=0.1
    local spin='/-\|'
    while ps -p $pid > /dev/null; do
        for i in $(seq 0 3); do
            printf "\r${spin:$i:1}"
            sleep $delay
        done
    done
    printf "\r"  # Clear the spinner
}

# Fetch the file list from the website
temp_file=$(mktemp)
if ! curl -s "$FILE_LIST_URL" | grep -oP '(?<=href=")[^"]+' | grep -E '^R-4\.[0-9]+(\.[0-9]+)?\.tar\.(gz|xz)$' > "$temp_file"; then
    echo "Failed to fetch or process file list from $FILE_LIST_URL."
    rm "$temp_file"
    exit 1
fi

# Prepare to check each file entry for size
authentic=0
result_file=$(mktemp)

# Start the file size checking in the background
(
    while IFS= read -r remote_name; do
        remote_file_url="${FILE_LIST_URL}${remote_name}"
        remote_size=$(curl -sI "$remote_file_url" | grep -i 'Content-Length' | awk '{print $2}' | tr -d '\r')

        if [ -z "$remote_size" ]; then
            echo "Failed to retrieve size for $remote_name."
            continue
        fi

        # Check if file name matches and compare sizes
        if [ "$file_name" == "$remote_name" ] && [ "$file_size" == "$remote_size" ]; then
            echo "Match found: $file_name ($file_size) == $remote_name ($remote_size)" >> "$result_file"
            authentic=1
            break
        fi
    done < "$temp_file"
    
    # Write the authentication result to the file
    if [ $authentic -eq 1 ]; then
        echo "authentic" > "$result_file"
    else
        echo "not authentic" > "$result_file"
    fi
) &

# Capture the PID of the background process
show_spinner $!

# Read the result from the temporary result file
if [ -f "$result_file" ]; then
    auth_result=$(cat "$result_file")
    if [ "$auth_result" == "authentic" ]; then
        echo "The file $LOCAL_TAR_FILE is authentic."
    else
       read -p "The file $LOCAL_TAR_FILE is NOT authentic. Do you want to continue? (y/n) " confirm
        if [ "$confirm" != "y" ]; then
            echo "Exiting..."
            exit 1
        fi    
    fi
fi

# Clean up
rm "$temp_file"
rm "$result_file"
