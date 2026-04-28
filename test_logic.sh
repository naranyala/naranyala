#!/bin/bash

# Configuration
USERNAME="testuser"
README_FILE="test_README.md"
GITHUB_TOKEN="mock_token"
AUTH_HEADER="Authorization: token $GITHUB_TOKEN"

echo "Testing script logic..."

# Mocked REPOS_JSON
REPOS_JSON='[
  {"id": 1, "name": "repo1", "html_url": "https://github.com/test/repo1", "stargazers_count": 10, "contributors_url": "https://api.github.com/repos/test/repo1/contributors"},
  {"id": 2, "name": "repo2", "html_url": "https://github.com/test/repo2", "stargazers_count": 5, "contributors_url": "https://api.github.com/repos/test/repo2/contributors"}
]'

# 1. Enrichment logic (simplified)
ENRICHED_REPOS_JSON="[]"
TEMP_ENRICHED_FILE=$(mktemp)
echo "[]" > "$TEMP_ENRICHED_FILE"

while read -r repo; do
  # Mocking the contributors count fetch (always 3)
  CONTRIBUTORS_COUNT=3
  jq --argjson repo "$repo" --argjson cc "$CONTRIBUTORS_COUNT" '. += [$repo + {contributors: $cc}]' "$TEMP_ENRICHED_FILE" > "${TEMP_ENRICHED_FILE}.tmp" && mv "${TEMP_ENRICHED_FILE}.tmp" "$TEMP_ENRICHED_FILE"
done < <(echo "$REPOS_JSON" | jq -c '.[]')

ENRICHED_REPOS_JSON=$(cat "$TEMP_ENRICHED_FILE")
rm "$TEMP_ENRICHED_FILE"

# 2. Sorting logic
SORTED_REPOS_JSON=$(echo "$ENRICHED_REPOS_JSON" | jq 'sort_by(.stargazers_count, .contributors) | reverse')

echo "Testing jq command..."

# 3. Table building logic
TABLE_CONTENT=$(echo "$SORTED_REPOS_JSON" | jq -r '
  [
    "| No. | Link | Stars | Contributors |",
    "|---|---|---|---|",
    (. | to_entries | map("| \(.key + 1) | [\(.value.name)](\(.value.html_url)) | \(.value.stargazers_count) | \(.value.contributors) |"))
  ] | flatten | join("\n")
')

echo "Generated Table Content:"
echo "$TABLE_CONTENT"

# Check if it looks correct
if echo "$TABLE_CONTENT" | grep -q "| 1 | \[repo1\](https://github.com/test/repo1) | 10 | 3 |"; then
  echo "SUCCESS: Table contains expected first row."
else
  echo "FAILURE: Table content mismatch (row 1)."
  echo "Content: $TABLE_CONTENT"
  exit 1
fi

if echo "$TABLE_CONTENT" | grep -q "| 2 | \[repo2\](https://github.com/test/repo2) | 5 | 3 |"; then
  echo "SUCCESS: Table contains expected second row."
else
  echo "FAILURE: Table content mismatch (row 2)."
  echo "Content: $TABLE_CONTENT"
  exit 1
fi
