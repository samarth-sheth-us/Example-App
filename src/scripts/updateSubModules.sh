#!/bin/bash

set -e

echo "🔄 Initializing and updating submodules..."
git submodule update --init --recursive

echo "📦 Reading submodule paths and branches from .gitmodules..."

ROOT_DIR=$(pwd)

# Read submodule paths and corresponding branches (default to 'main' if not specified)
grep '\[submodule' .gitmodules | sed 's/.*"\(.*\)"/\1/' | while read -r name; do
    path=$(git config -f .gitmodules --get submodule."$name".path)
    branch=$(git config -f .gitmodules --get submodule."$name".branch || echo "main")

    echo "--------------------------------------------"
    echo "📂 Processing submodule: $path (branch: $branch)"

    if [ ! -d "$path" ]; then
        echo "❌ Directory $path does not exist. Skipping."
        continue
    fi

    cd "$path"

    if git ls-remote --exit-code --heads origin "$branch" >/dev/null 2>&1; then
        echo "✅ Switching to '$branch' branch in $path"
        git fetch origin "$branch"
        git checkout "$branch"
        git pull origin "$branch"
    else
        echo "⚠️ Branch '$branch' not found in $path — skipping checkout."
    fi

    # Collect and install dependencies in root
    if [ -f package.json ]; then
        echo "📦 Extracting dependencies from $path/package.json"
        MODULE_DEPS=$(jq -r '.dependencies | to_entries[] | "\(.key)@\(.value | ltrimstr("^"))"' package.json)

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

echo "✅ All submodules checked out to specified branches and dependencies installed."
