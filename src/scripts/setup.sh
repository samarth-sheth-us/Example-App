#!/bin/bash

# Exit immediately on error
set -e

echo "🔄 Initializing and updating submodules..."
git submodule update --init --recursive

echo "📦 Reading submodule paths from .gitmodules..."

# Extract submodule paths from .gitmodules
SUBMODULE_PATHS=$(grep path .gitmodules | awk -F' = ' '{ print $2 }')

# Track root directory
ROOT_DIR=$(pwd)

for path in $SUBMODULE_PATHS; do
    echo "--------------------------------------------"
    echo "📂 Processing submodule: $path"

    if [ ! -d "$path" ]; then
        echo "❌ Directory $path does not exist. Skipping."
        continue
    fi

    cd "$path"

    # Check and switch to 'main' branch if it exists
    if git show-ref --verify --quiet refs/heads/main || git ls-remote --exit-code --heads origin main >/dev/null 2>&1; then
        echo "✅ Switching to 'main' branch in $path"
        git fetch origin main
        git checkout main
        git pull origin main
    else
        echo "⚠️ No 'main' branch found in $path — skipping checkout."
    fi

    # Collect dependencies
    if [ -f package.json ]; then
        echo "📦 Extracting dependencies from $path/package.json"

        MODULE_DEPS=$(jq -r '.dependencies | to_entries[] | "\(.key)@\(.value | ltrimstr("^"))"' package.json)

        # Move back to root project and install the deps
        cd "$ROOT_DIR"
        if [ ! -z "$MODULE_DEPS" ]; then
            echo "📦 Installing submodule dependencies into root project: $MODULE_DEPS"
            npm install $MODULE_DEPS
        else
            echo "ℹ️ No dependencies found in $path"
        fi
    else
        echo "⚠️ No package.json found in $path"
        cd "$ROOT_DIR"
    fi
done

echo "✅ All submodule dependencies installed in root project."
