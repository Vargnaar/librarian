#!/bin/bash


# Directory to watch for incoming zip files.
WATCH_DIR=""

# The destination directory for the extracted audio files.
DEST_DIR=""

# List of audio file extensions to move.
AUDIO_EXTENSIONS=("mp3" "m4a" "flac" "ogg")


LOCK_FILE="/tmp/process_audiobooks.lock"

if [ -f "$LOCK_FILE" ]; then
    echo "Error: Another instance of the script is already running."
    echo "Lock file exists at $LOCK_FILE."
    exit 1
fi


touch "$LOCK_FILE"


trap 'rm -f "$LOCK_FILE"; exit' INT TERM EXIT


if [ ! -d "$DEST_DIR" ]; then
    echo "Error: Destination directory '$DEST_DIR' does not exist or is not a directory."
    rm -f "$LOCK_FILE"
    exit 1
fi

echo "Script started. Watching '$WATCH_DIR' for new zip files."

inotifywait -m -e close_write "$WATCH_DIR" |
while read path action file; do
    echo "File event detected: $action on file '$file' in path '$path'"

    if [[ "$file" =~ \.zip$ ]]; then
        echo "Processing new zip file: '$file'"

        TEMP_DIR=$(mktemp -d)
        echo "Temporary directory created: '$TEMP_DIR'"

        if unzip -q "$WATCH_DIR/$file" -d "$TEMP_DIR"; then
            echo "Unzipping successful. Searching for audio files..."

            
            BOOK_FOLDER_NAME="${file%.zip}"
            BOOK_DIR="$DEST_DIR/$BOOK_FOLDER_NAME"
            mkdir -p "$BOOK_DIR"
            echo "Created new audiobook directory: '$BOOK_DIR'"

            
            FIND_ARGS=""
            for ext in "${AUDIO_EXTENSIONS[@]}"; do
                FIND_ARGS+="-o -name \"*.${ext}\" "
            done
            FIND_ARGS=${FIND_ARGS:3}
            
            
            eval "find \"$TEMP_DIR\" -type f \( $FIND_ARGS \)" -print0 | while IFS= read -r -d $'\0' audio_file; do
                echo "Found audio file: '$audio_file'"
                if mv -v "$audio_file" "$BOOK_DIR"; then
                    echo "Successfully moved: '$audio_file' to '$BOOK_DIR'"
                else
                    echo "Error moving file: '$audio_file'"
                fi
            done
            
            echo "Audio file processing complete. Cleaning up..."

            rm -r "$TEMP_DIR"
            echo "Temporary directory '$TEMP_DIR' deleted."

            if rm -f "$WATCH_DIR/$file"; then
                echo "Successfully deleted original zip file: '$file'"
            else
                echo "Error deleting original zip file: '$file'"
            fi
        else
            echo "Error unzipping '$file'. The file may be corrupt or incomplete."
            echo "Processing stopped for this file. Please check its integrity."
        fi

        echo "Finished processing '$file'"
    fi
done
