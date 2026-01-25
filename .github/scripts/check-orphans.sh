#!/bin/bash
set -e

echo "🔍 Checking for orphaned files..."

WARNINGS=0
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to normalize path (works on both Linux and macOS)
normalize_path() {
  local path="$1"
  # Change to directory and get pwd, or handle file
  if [ -d "$path" ]; then
    (cd "$path" && pwd)
  elif [ -f "$path" ]; then
    (cd "$(dirname "$path")" && echo "$(pwd)/$(basename "$path")")
  else
    # Path doesn't exist, manually normalize
    echo "$path" | sed 's|/\./|/|g' | sed 's|//|/|g' | sed 's|^\./||'
  fi
}

# Function to decode URL-encoded strings
url_decode() {
  local url_encoded="${1//+/ }"
  printf '%b' "${url_encoded//%/\\x}"
}

# Get all referenced markdown files
REFERENCED_FILES=$(mktemp)

# Extract all markdown links from all files (using while loop to handle spaces)
find . -name "*.md" -not -path "./.git/*" -not -path "./node_modules/*" -print0 | while IFS= read -r -d '' file; do
  # Find markdown links: [text](path.md) - using basic grep and sed instead of grep -P
  grep -o '\[.*\](.*\.md)' "$file" 2>/dev/null | sed -n 's/.*](\([^)]*\.md\)).*/\1/p' | while read -r link; do
    # Skip URLs
    if [[ "$link" =~ ^https?:// ]]; then
      continue
    fi

    # Decode URL-encoded characters (like %20 for spaces)
    link=$(url_decode "$link")

    # Resolve relative paths
    dir=$(dirname "$file")
    if [[ "$link" == /* ]]; then
      # Absolute path
      resolved="$link"
    else
      # Relative path - combine and normalize
      resolved=$(normalize_path "$dir/$link")
    fi
    echo "$resolved" >> "$REFERENCED_FILES"
  done
done

# Sort and unique referenced files
sort -u "$REFERENCED_FILES" -o "$REFERENCED_FILES"

# Check each markdown file
echo ""
echo "Checking for orphaned files (not referenced by any other file)..."

# Files that should be entry points (not considered orphans)
ENTRY_POINTS=(
  "./README.md"
  "./KCNA_CHEATSHEET.md"
  "./labs/README.md"
)

# Check each markdown file for orphans
find . -name "*.md" -not -path "./.git/*" -not -path "./node_modules/*" -print0 | while IFS= read -r -d '' md_file; do
  full_path=$(normalize_path "$md_file")

  # Skip entry point files
  is_entry_point=false
  for entry in "${ENTRY_POINTS[@]}"; do
    entry_full=$(normalize_path "$entry")
    if [ "$full_path" = "$entry_full" ]; then
      is_entry_point=true
      break
    fi
  done

  if [ "$is_entry_point" = true ]; then
    continue
  fi

  # Check if file is referenced
  if ! grep -q "^$full_path$" "$REFERENCED_FILES"; then
    echo -e "${YELLOW}⚠️  Potentially orphaned file: $md_file${NC}"
    WARNINGS=$((WARNINGS + 1))
  fi
done

# Cleanup
rm "$REFERENCED_FILES"

echo ""
echo "========================================"
if [ $WARNINGS -eq 0 ]; then
  echo -e "${GREEN}✅ No orphaned files detected!${NC}"
else
  echo -e "${YELLOW}⚠️  Found $WARNINGS potentially orphaned file(s)${NC}"
  echo "Note: This is a warning only. Some files may intentionally not be linked."
fi

# Don't fail the build on warnings
exit 0
