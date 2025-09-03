# Mimir

A simple and lightweight Bash script designed to automate the processing of audiobook ZIP files. When a ZIP file is uploaded to a designated "staging" directory, this script automatically unzips it, moves the audio files to a primary library, and deletes the original archive to save space.

This script is built using `inotify-tools` to reliably trigger the process only after a file transfer is complete, preventing race conditions and file corruption.

## Features

- **Automated Processing:** Automatically handles new ZIP files as they are uploaded.
- **Race Condition-Safe:** Uses the `inotify` `close_write` event to ensure the script only processes files that have been fully transferred.
- **Directory Cleanup:** Deletes the original ZIP file after successful processing to conserve disk space.
- **Robust Logging:** Provides detailed logging to a separate file, making it easy to monitor the script's activity and troubleshoot any issues.

## Prerequisites

1.  **A Linux System:** This script is designed for Linux systems, specifically tested on Raspberry Pi OS.
2.  **`unzip`:** A standard utility for decompressing ZIP archives.
    ```bash
    sudo apt-get install unzip
    ```
3.  **`inotify-tools`:** A crucial utility for watching file system events.
    ```bash
    sudo apt-get install inotify-tools
    ```

## Installation and Configuration

Follow these steps to get the script up and running on your system.

### 1. Create Directories

First, create the directories the script will use. The `audiobookshelf` directory is where your library is located, and the `zip` subdirectory will be the staging area for new uploads.

```bash
mkdir -p /path/to/your/audiobookshelf/audiobooks/zip
