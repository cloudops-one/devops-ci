#!/bin/bash
# sanitize-branch-name.sh
# Sanitize branch name for use in DNS and Docker tags

branch_name="$1"
# Replace invalid characters with dashes and convert to lowercase
sanitized=$(echo "$branch_name" | sed -e 's/[^a-zA-Z0-9-]/-/g' | tr '[:upper:]' '[:lower:]')

# Ensure it doesn't start or end with a dash
sanitized=$(echo "$sanitized" | sed -e 's/^-//' -e 's/-$//')

# Limit length to 30 characters
sanitized=$(echo "$sanitized" | cut -c 1-30)
echo "$sanitized"