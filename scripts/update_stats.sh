#!/bin/bash

# Configuration
# It's better to use an environment variable if possible, 
# but for this example we'll default to a placeholder or allow it to be passed.
USERNAME="${GITHUB_USERNAME:-naranyala}"
OUTPUT_DIR="profile"

# URLs for the SVGs
# Note: These URLs are examples based on common GitHub profile stat services.
# You should adjust them to match the services you are actually using.
declare -A files
files["stats.svg"]="https://github-readme-stats.vercel.app/api?username=$USERNAME&show_icons=true&theme=dark"
files["stats-dark.svg"]="https://github-readme-stats.vercel.app/api?username=$USERNAME&show_icons=true&theme=dark"
files["stats-light.svg"]="https://github-readme-stats.vercel.app/api?username=$USERNAME&show_icons=true&theme=light"
files["top-langs-dark.svg"]="https://github-readme-stats.vercel.app/api/top-langs/?username=$USERNAME&layout=compact&theme=dark"
files["top-langs-light.svg"]="https://github-readme-stats.vercel.app/api/top-langs/?username=$USERNAME&layout=compact&theme=light"
files["streak-dark.svg"]="https://github-readme-streak-stats.herokuapp.com/?user=$USERNAME&theme=dark"
files["streak-light.svg"]="https://github-readme-streak-stats.herokuapp.com/?user=$USERNAME&theme=light"

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Download each file
for file in "${!files[@]}"; do
  echo "Downloading $file from ${files[$file]}..."
  curl -s -o "$OUTPUT_DIR/$file" "${files[$file]}"
  
  if [ $? -ne 0 ]; then
    echo "Error downloading $file"
  fi
done

echo "Update complete."
