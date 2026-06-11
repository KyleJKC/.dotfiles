# =============================================================================
# Environment variables
# =============================================================================
set -gx fish_greeting ""

# Disable virtualenv/conda prompt modification (we render our own)
set -gx CONDA_CHANGEPS1 no

set -gx EDITOR nvim

# Bat
set -gx BAT_THEME "rose-pine-moon"

# FZF (Rose Pine Moon palette)
set -gx FZF_DEFAULT_OPTS "\
--cycle --layout=reverse --border --height=90% --preview-window=wrap --marker='*' \
--color=fg:#908caa,bg:#232136,hl:#ea9a97 \
--color=fg+:#e0def4,bg+:#393552,hl+:#ea9a97 \
--color=border:#44415a,header:#3e8fb0,gutter:#232136 \
--color=spinner:#f6c177,info:#9ccfd8 \
--color=pointer:#c4a7e7,marker:#eb6f92,prompt:#908caa"

# fzf.fish preview commands
set -g fzf_preview_dir_cmd eza --icons --group-directories-first --color=always --all
set -g fzf_preview_file_cmd bat --color=always --style=numbers
