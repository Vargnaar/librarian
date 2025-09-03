# Take all mp3 files in the current folder, create a folder based on the name and then move the file to the folder
for file in *'.mp3'; do
    if [[ -f "$file" ]]; then
        dir_name="${file%.mp3}"
        mkdir -p "$dir_name"
        mv "$file" "$dir_name"
    fi
done
