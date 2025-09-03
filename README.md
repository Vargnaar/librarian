# Mimir

A simple and lightweight Bash script designed to automate the processing of audiobook ZIP files. When a ZIP file is uploaded to a designated "staging" directory, this script automatically unzips it, moves the audio files to a primary library, and deletes the original archive to save space.

This script is built using `inotify-tools` to reliably trigger the process only after a file transfer is complete, preventing race conditions and file corruption.

Added lock-file checking to prevent fork-bombing myself 😒
Logging added to help debug the annoying nonsense
Added an organiser script; will integrate eventually.
