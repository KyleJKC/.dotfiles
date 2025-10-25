if status is-interactive
    if not functions -q fisher
        echo "⏳ Installing fisher..."
        curl --silent --location https://git.io/fisher | source
        and fisher install jorgebucaran/fisher
        and fisher install jorgebucaran/autopair.fish
    end
end

set -gx fish_greeting ""

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
alias reload='source ~/.config/fish/config.fish'
alias lg='lazygit'

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
if test -f /opt/miniconda3/bin/conda
    eval /opt/miniconda3/bin/conda "shell.fish" "hook" $argv | source
else
    if test -f "/opt/miniconda3/etc/fish/conf.d/conda.fish"
        . "/opt/miniconda3/etc/fish/conf.d/conda.fish"
    else
        set -x PATH "/opt/miniconda3/bin" $PATH
    end
end
# <<< conda initialize <<<

if test -x /opt/homebrew/bin/brew
    eval (/opt/homebrew/bin/brew shellenv fish)
end

set -gx BUN_INSTALL $HOME/.bun
fish_add_path -g $BUN_INSTALL/bin

starship init fish | source
zoxide init fish | source