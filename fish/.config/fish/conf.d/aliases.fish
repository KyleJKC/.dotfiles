# =============================================================================
# Aliases
# =============================================================================
alias c='clear'
alias ls='eza --icons --group-directories-first' # Make sure you installed eza
alias l='ls -a'
alias ll='ls -lh'
alias la='ll -a'
alias tree='ls --tree'
alias vi='vim'
alias vim='/opt/homebrew/bin/vim'
alias grep="grep --color=auto"
alias s='fastfetch'
alias x='extract'
alias mp='mkdir -p'
alias ra='joshuto'
alias rm='rm -i'
alias lg='lazygit'

# Fully restart the shell — cleaner than re-sourcing config.fish, which would
# duplicate PATH entries and re-run one-time setup.
alias reload='exec fish'
