#!/bin/bash

WATCH_DIR="/path/to/your/audiobookshelf/audiobooks/zip"


DEST_DIR="/path/to/your/audiobookshelf/audiobooks"


AUDIO_EXTENSIONS=("mp3" "m4a" "flac" "ogg")


if [ ! -d "$DEST_DIR" ]; then
    echo "Error: Destination directory '$DEST_DIR' does not exist or is not a directory."
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
            
            
            FIND_ARGS=""
            for ext in "${AUDIO_EXTENSIONS[@]}"; do
                FIND_ARGS+="-o -name \"*.${ext}\" "
            done
            
            FIND_ARGS=${FIND_ARGS:3}
            
            
            eval "find \"$TEMP_DIR\" -type f \( $FIND_ARGS \)" -print0 | while IFS= read -r -d $'\0' audio_file; do
                echo "Found audio file: '$audio_file'"
                if mv -v "$audio_file" "$DEST_DIR"; then
                    echo "Successfully moved: '$audio_file'"
                else
                    echo "Error moving file: '$audio_file'"
                fi
            done
            
            echo "Audio file processing complete. Cleaning up..."
            
            
            rm -r "$TEMP_DIR"
            echo "Temporary directory '$TEMP_DIR' deleted."
            
            # Delete the original zip file
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
