#!/bin/bash
set -e

echo "🔍 Validating repository structure..."

ERRORS=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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

# Check that all domain README files exist
echo "📁 Checking domain structure..."
DOMAIN_DIRS=(
  "domains/01-Kubernetes Fundamentals"
  "domains/02-Container Orchestration"
  "domains/03-Cloud Native Application Delivery"
  "domains/04-Cloud Native Architecture"
)

for dir in "${DOMAIN_DIRS[@]}"; do
  if [ ! -f "$dir/README.md" ]; then
    echo -e "${RED}❌ Missing README.md in $dir${NC}"
    ERRORS=$((ERRORS + 1))
  else
    echo -e "${GREEN}✓${NC} $dir/README.md exists"
  fi
done

# Check that all lab directories have corresponding domain
echo ""
echo "🧪 Checking lab structure..."
LAB_DIRS=(
  "labs/01-kubernetes-fundamentals"
  "labs/02-container-orchestration"
  "labs/03-cloud-native-application-delivery"
  "labs/04-cloud-native-architecture"
)

for dir in "${LAB_DIRS[@]}"; do
  if [ ! -d "$dir" ]; then
    echo -e "${RED}❌ Missing lab directory: $dir${NC}"
    ERRORS=$((ERRORS + 1))
  else
    LAB_COUNT=$(find "$dir" -name "lab-*.md" | wc -l)
    echo -e "${GREEN}✓${NC} $dir exists with $LAB_COUNT lab files"
  fi
done

# Verify cross-references between domains and labs
echo ""
echo "🔗 Checking cross-references..."

# Extract lab links from domain README files
for domain_readme in domains/*/README.md; do
  echo "Checking: $domain_readme"

  # Find all lab links in the README
  while IFS= read -r line; do
    if [[ $line =~ \[.*\]\((.*lab-[0-9]+.*\.md)\) ]]; then
      lab_link="${BASH_REMATCH[1]}"

      # Resolve relative path from domain README location
      domain_dir=$(dirname "$domain_readme")
      resolved_path="$domain_dir/$lab_link"

      # Normalize path
      normalized_path=$(normalize_path "$resolved_path")

      if [ ! -f "$normalized_path" ]; then
        echo -e "${RED}❌ Broken link in $domain_readme: $lab_link${NC}"
        echo -e "   Resolved to: $normalized_path"
        ERRORS=$((ERRORS + 1))
      fi
    fi
  done < "$domain_readme"
done

# Check for required root files
echo ""
echo "📄 Checking required root files..."
REQUIRED_FILES=(
  "README.md"
  "KCNA_CHEATSHEET.md"
)

for file in "${REQUIRED_FILES[@]}"; do
  if [ ! -f "$file" ]; then
    echo -e "${RED}❌ Missing required file: $file${NC}"
    ERRORS=$((ERRORS + 1))
  else
    echo -e "${GREEN}✓${NC} $file exists"
  fi
done

# Final report
echo ""
echo "========================================"
if [ $ERRORS -eq 0 ]; then
  echo -e "${GREEN}✅ Structure validation passed!${NC}"
  exit 0
else
  echo -e "${RED}❌ Structure validation failed with $ERRORS error(s)${NC}"
  exit 1
fi
