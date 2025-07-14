#!/bin/bash

# Usage: ./solo-pr.sh "Your commit message here"

COMMIT_MSG=$1

if [ -z "$COMMIT_MSG" ]; then
  echo "Usage: ./solo-pr.sh \"Commit message\""
  exit 1
fi

# Check for staged changes
if ! git diff --cached --quiet; then
  :
else
  echo "No staged changes to commit. Please stage your changes before running this script."
  exit 1
fi

# Step 1: Generate branch name from commit message
BRANCH_NAME=$(echo "$COMMIT_MSG" \
  | tr '[:upper:]' '[:lower:]' \
  | sed -E 's/[^a-z0-9]+/-/g' \
  | sed -E 's/^-+|-+$//g' \
  | cut -c1-50)  # Limit to 50 chars

echo "Creating branch: $BRANCH_NAME"

# Step 2: Create new branch and commit
git checkout -b "$BRANCH_NAME"
# git add . # we will manually add files so that we only commit the changes we want
git commit -m "$COMMIT_MSG"

# Step 3: Push branch
git push -u origin "$BRANCH_NAME"

# Step 4: Create PR
gh pr create --title "$COMMIT_MSG" --base main --head "$BRANCH_NAME"

# Step 5: Merge PR
gh pr merge "$BRANCH_NAME" --squash --delete-branch

# Step 6: Return to main and pull
git checkout main
git pull origin main
