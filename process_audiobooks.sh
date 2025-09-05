#!/bin/bash

# Directory to watch for incoming zip files.
WATCH_DIR=""

# The destination directory for the extracted audio files.
DEST_DIR=""

# List of audio file extensions to move.
AUDIO_EXTENSIONS=("mp3" "m4a" "flac" "ogg")

LOCK_FILE="/tmp/process_audiobooks.lock"

# Logging functions with timestamps and levels
log_info() {
    echo "[$(date '+%d-%m-%Y %H:%M:%S')] [INFO] $1"
}

log_error() {
    echo "[$(date '+%d-%m-%Y %H:%M:%S')] [ERROR] $1" >&2
}

log_success() {
    echo "[$(date '+%d-%m-%Y %H:%M:%S')] [SUCCESS] $1"
}

log_warning() {
    echo "[$(date '+%d-%m-%Y %H:%M:%S')] [WARNING] $1"
}

log_debug() {
    echo "[$(date '+%d-%m-%Y %H:%M:%S')] [DEBUG] $1"
}

if [ -f "$LOCK_FILE" ]; then
    log_error "Another instance of the script is already running."
    log_error "Lock file exists at $LOCK_FILE."
    exit 1
fi

touch "$LOCK_FILE"
log_debug "Lock file created at $LOCK_FILE"

trap 'log_info "Cleaning up and exiting..."; rm -f "$LOCK_FILE"; exit' INT TERM EXIT

if [ ! -d "$DEST_DIR" ]; then
    log_error "Destination directory '$DEST_DIR' does not exist or is not a directory."
    rm -f "$LOCK_FILE"
    exit 1
fi

log_info "=========================================="
log_info "Audiobook Processing Script Started"
log_info "=========================================="
log_info "Watch directory: '$WATCH_DIR'"
log_info "Destination directory: '$DEST_DIR'"
log_info "Supported audio extensions: ${AUDIO_EXTENSIONS[*]}"
log_info "Monitoring for new zip files..."

inotifywait -m -e close_write "$WATCH_DIR" |
while read path action file; do
    log_debug "File event detected: $action on file '$file' in path '$path'"

    if [[ "$file" =~ \.zip$ ]]; then
        log_info "==========================================
        log_info "Processing new zip file: '$file'"
        log_info "=========================================="

        TEMP_DIR=$(mktemp -d)
        log_debug "Temporary directory created: '$TEMP_DIR'"

        log_info "Attempting to extract zip file..."
        if unzip -q "$WATCH_DIR/$file" -d "$TEMP_DIR"; then
            log_success "Zip file extracted successfully"
            log_info "Searching for audio files..."

            BOOK_FOLDER_NAME="${file%.zip}"
            BOOK_DIR="$DEST_DIR/$BOOK_FOLDER_NAME"
            mkdir -p "$BOOK_DIR"
            log_success "Created audiobook directory: '$BOOK_DIR'"

            # Build find arguments for audio extensions
            FIND_ARGS=""
            for ext in "${AUDIO_EXTENSIONS[@]}"; do
                FIND_ARGS+="-o -name \"*.${ext}\" "
            done
            FIND_ARGS=${FIND_ARGS:3}
            
            # Find and process audio files
            AUDIO_COUNT=0
            eval "find \"$TEMP_DIR\" -type f \( $FIND_ARGS \)" -print0 | while IFS= read -r -d $'\0' audio_file; do
                AUDIO_COUNT=$((AUDIO_COUNT + 1))
                log_debug "Found audio file ($AUDIO_COUNT): '$(basename "$audio_file")'"
                
                if mv -v "$audio_file" "$BOOK_DIR" >/dev/null 2>&1; then
                    log_success "Moved: '$(basename "$audio_file")' → '$BOOK_DIR'"
                else
                    log_error "Failed to move: '$(basename "$audio_file")'"
                fi
            done
            
            log_info "Audio file processing complete"
            log_info "Cleaning up temporary files..."

            if rm -r "$TEMP_DIR"; then
                log_debug "Temporary directory '$TEMP_DIR' deleted successfully"
            else
                log_warning "Could not fully clean temporary directory '$TEMP_DIR'"
            fi

            log_info "Removing original zip file..."
            if rm -f "$WATCH_DIR/$file"; then
                log_success "Original zip file '$file' deleted successfully"
            else
                log_error "Failed to delete original zip file: '$file'"
            fi
        else
            log_error "Failed to extract '$file' - file may be corrupt or incomplete"
            log_warning "Skipping processing for this file"
            log_info "Please check file integrity and try again"
            
            # Clean up temp directory even on failure
            if [ -d "$TEMP_DIR" ]; then
                rm -r "$TEMP_DIR"
                log_debug "Cleaned up temporary directory after extraction failure"
            fi
        fi

        log_info "Completed processing: '$file'"
        log_info "------------------------------------------"
    fi
done
