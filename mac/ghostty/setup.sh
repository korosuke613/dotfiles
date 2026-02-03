#!/bin/sh

# this dir path
DIR="$(cd "$(dirname "$0")" && pwd)"

trash "$HOME/Library/Application Support/com.mitchellh.ghostty/config"
ln -s "$DIR/config" "$HOME/Library/Application Support/com.mitchellh.ghostty/config"
