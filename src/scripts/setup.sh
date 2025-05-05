#!/bin/bash

git submodule update --init --recursive

# Save the current directory (main project root)
ROOT_DIR=$(pwd)

# Path to your submodule
SUBMODULE_DIR="src/modules"

# Navigate to the submodule directory
cd "$SUBMODULE_DIR" || exit 1

echo "Installing exact dependencies from $SUBMODULE_DIR/package.json"

# Parse dependencies and install with exact versions
DEPS=$(jq -r '.dependencies | to_entries[] | "\(.key)@\(.value)"' package.json)

if [ -z "$DEPS" ]; then
    echo "No dependencies found."
else
    cd "$ROOT_DIR"
    echo "Running: npm install $DEPS"
    npm install $DEPS
fi
