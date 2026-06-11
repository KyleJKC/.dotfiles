#!/bin/bash
if [ -d "$1" ]; then
    eza --tree --level=2 --color=always --icons "$1"
elif [ -f "$1" ]; then
    case "$1" in
        *.md) glow -s dark "$1" ;;
        *.json) jq -C '.' "$1" ;;
        *) bat --color=always --style=numbers "$1" ;;
    esac
fi
