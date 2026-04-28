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

# 1. Fetch repos from API
REPOS_JSON=$(curl -s -H "$AUTH_HEADER" "https://api.github.com/users/$USERNAME/repos?per_page=100&sort=updated")

if ! echo "$REPOS_JSON" | jq -e 'if type == "array" then true else false end' >/dev/null 2>&1; then
  echo "Error: Could not fetch repositories or API returned non-array response."
  echo "Response snippet: $(echo "$REPOS_JSON" | head -c 100)"
  exit 1
fi

echo "Enriching repository data with contributors count..."

# 2. Enrich JSON with contributors count
# We'll build a new JSON array.
ENRICHED_REPOS_JSON="[]"

# Use a temporary file to avoid issues with large strings in variables
TEMP_ENRICHED_FILE=$(mktemp)
echo "[]" > "$TEMP_ENRICHED_FILE"

while read -r repo; do
  CONTRIBUTORS_URL=$(echo "$repo" | jq -r '.contributors_url')
  
  CONTRIBUTORS_COUNT=0
  if [ -n "$CONTRIBUTORS_URL" ] && [ "$CONTRIBUTORS_URL" != "null" ]; then
    # Fetch contributors response
    CONT_RESPONSE=$(curl -s -H "$AUTH_HEADER" "$CONTRIBUTORS_URL")
    
    # Check if response is valid JSON array
    if echo "$CONT_RESPONSE" | jq -e 'if type == "array" then true else false end' >/dev/null 2>&1; then
      CONTRIBUTORS_COUNT=$(echo "$CONT_RESPONSE" | jq '. | length')
    else
      echo "Warning: Non-JSON or non-array response for $CONTRIBUTORS_URL. Setting contributors to 0."
    fi
  fi

  # Append to the enriched JSON array using jq and a temporary file
  jq --argjson repo "$repo" --argjson cc "$CONTRIBUTORS_COUNT" '. += [$repo + {contributors: $cc}]' "$TEMP_ENRICHED_FILE" > "${TEMP_ENRICHED_FILE}.tmp" && mv "${TEMP_ENRICHED_FILE}.tmp" "$TEMP_ENRICHED_FILE"

done < <(echo "$REPOS_JSON" | jq -c '.[]')

ENRICHED_REPOS_JSON=$(cat "$TEMP_ENRICHED_FILE")
rm "$TEMP_ENRICHED_FILE"

echo "Sorting repositories by stars and then contributors (descending)..."

# 3. Sort enriched JSON: Stars DESC, then Contributors DESC
SORTED_REPOS_JSON=$(echo "$ENRICHED_REPOS_JSON" | jq -s 'sort_by(.stargazers_count, .contributors) | reverse')

echo "Building the repository table..."

# 4. Build the Markdown table
# We use jq to generate the table rows directly to ensure correctness and handle special characters
TABLE_CONTENT=$(echo "$SORTED_REPOS_JSON" | jq -r '
  "| id | link | stars | contributors |\n|---|---|---|---|" + 
  (.[] | "\n| \(.id) | [\(.name)](\(.html_url)) | \(.stargazers_count) | \(.contributors) |")
')

# Wrap in collapsible details section
WRAPPED_CONTENT="<details>\n<summary>Click to see my repositories 🚀</summary>\n\n${TABLE_CONTENT}\n\n</details>"
FINAL_MARKDOWN=$(printf "$WRAPPED_CONTENT")

echo "Updating $README_FILE with the new list..."

# Save the new block to a temporary file to avoid shell escaping issues
echo "<!-- REPOS_LIST_START -->" > temp_block.txt
echo "$FINAL_MARKDOWN" >> temp_block.txt
echo "<!-- REPOS_LIST_END -->" >> temp_block.txt

# Use Python to replace the block between the markers
python3 -c "
import re
import sys

readme_path = '$README_FILE'
block_path = 'temp_block.txt'

try:
    with open(block_path, 'r') as f:
        new_block = f.read()

    with open(readme_path, 'r') as f:
        content = f.read()

    pattern = r'<!-- REPOS_LIST_START -->.*?<!-- REPOS_LIST_END -->'
    if re.search(pattern, content, re.DOTALL):
        updated_content = re.sub(pattern, new_block, content, flags=re.DOTALL)
        with open(readme_path, 'w') as f:
            f.write(updated_content)
        print('Successfully updated README.md')
    else:
        print('Error: Could not find the REPOS_LIST tags in README.md')
        sys.exit(1)
except Exception as e:
    print(f'Error: {e}')
    sys.exit(1)
"

rm temp_block.txt

echo "Repository list updated successfully!"
