#!/bin/bash

# Exit immediately on error
set -e

echo "🔄 Initializing and updating submodules..."
git submodule update --init --recursive

echo "📦 Reading submodule paths, branches, and tags from .gitmodules..."

# Track root directory
ROOT_DIR=$(pwd)

# Get all submodule names
SUBMODULE_NAMES=$(git config --file .gitmodules --get-regexp path | awk '{ print $1 }' | sed 's/^submodule\.//;s/\.path$//')

for name in $SUBMODULE_NAMES; do
    path=$(git config --file .gitmodules submodule."$name".path)
    url=$(git config --file .gitmodules submodule."$name".url)
    branch=$(git config --file .gitmodules submodule."$name".branch)
    tag=$(git config --file .gitmodules submodule."$name".tag)

    echo "--------------------------------------------"
    echo "📂 Processing submodule: $path"
    echo "🔗 Repo: $url"
    if [ -n "$tag" ]; then
        echo "🏷️ Tag: $tag"
    elif [ -n "$branch" ]; then
        echo "🌿 Branch: $branch"
    else
        echo "🌿 No branch or tag specified — defaulting to 'main'"
        branch="main"
    fi

    if [ ! -d "$path" ]; then
        echo "❌ Directory $path does not exist. Skipping."
        continue
    fi

    cd "$path"

    if [ -n "$tag" ]; then
        # Fetch and checkout tag
        git fetch --tags
        if git rev-parse "$tag" >/dev/null 2>&1; then
            git checkout "$tag"
        else
            echo "❌ Tag '$tag' not found in $path"
        fi
    elif [ -n "$branch" ]; then
        # Fetch and checkout branch
        if git ls-remote --exit-code --heads origin "$branch" >/dev/null 2>&1; then
            git fetch origin "$branch"
            git checkout "$branch"
            git pull origin "$branch"
        else
            echo "⚠️ Branch '$branch' not found in $path"
        fi
    fi

    # Collect dependencies
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

echo "✅ All submodules processed."
