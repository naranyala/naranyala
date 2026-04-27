#!/bin/bash

# Configuration
USERNAME="naranyala"
README_FILE="README.md"

echo "Fetching repositories for $USERNAME..."

# We use the GITHUB_TOKEN provided by GitHub Actions to avoid rate limits.
# If running locally, it will just use an unauthenticated request.
if [ -n "$GITHUB_TOKEN" ]; then
  AUTH_HEADER="Authorization: token $GITHUB_TOKEN"
else
  AUTH_HEADER=""
fi

# 1. Fetch repos from API (sorted by most recently updated)
# 2. Use jq to format them as a Markdown list: - [name](url)
# 3. We limit to 100 repos (GitHub API default max per page)
REPOS_MARKDOWN=$(curl -s -H "$AUTH_HEADER" "https://api.github.com/users/$USERNAME/repos?per_page=100&sort=updated" | \
  jq -r '.[] | "- [\(.name)](https://github.com/\($USERNAME)/\(.name))"')

if [ -z "$REPOS_MARKDOWN" ]; then
  echo "Error: Could not fetch repositories or no repositories found."
  exit 1
fi

echo "Updating $README_FILE with the new list..."

# Use sed to replace everything between the markers
# We use a temporary file to avoid issues with sed and large strings
cat <<EOF > temp_repos.txt
<!-- REPOS_LIST_START -->
$REPOS_MARKDOWN
<!-- REPOS_LIST_END -->
EOF

# This sed command finds the block between the markers and replaces it with the content of our temp file
# Note: We use a slightly more robust way to replace the block in GNU sed
sed -i "/<!-- REPOS_LIST_START -->/,/<!-- REPOS_LIST_END -->/ {
    /<!-- REPOS_LIST_START -->/! {
        /<!-- REPOS_LIST_END -->/! d
    }
    /<!-- REPOS_LIST_START -->/d
    /<!-- REPOS_LIST_END -->/d
}" "$README_FILE"

# Re-inserting the block properly using a more reliable method for automation
# We'll use a perl-based approach or a simple python snippet since sed can be tricky with multiline replacements
python3 -c "
import sys

with open('$README_FILE', 'r') as f:
    content = f.read()

new_block = \"\"\"<!-- REPOS_LIST_START -->
$REPOS_MARKDOWN
<!-- REPOS_LIST_END -->\"\"\"

import re
pattern = r'<!-- REPOS_LIST_START -->.*?<!-- REPOS_LIST_END -->'
updated_content = re.sub(pattern, new_block, content, flags=re.DOTALL)

with open('$README_FILE', 'w') as f:
    f.write(updated_content)
"

rm temp_repos.txt

echo "Repository list updated successfully!"
