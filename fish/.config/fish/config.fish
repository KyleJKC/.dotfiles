if status is-interactive
    if not functions -q fisher
        echo "⏳ Installing fisher..."
        curl --silent --location https://git.io/fisher | source
        and fisher update
    end
end

set -gx fish_greeting ""

# Disable virtualenv/conda prompt modification
set -gx CONDA_CHANGEPS1 no

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
# OPTIMIZED: Lazy-load conda - only initialize when conda is actually called
if test -f /opt/miniconda3/bin/conda
    # Just add to PATH, don't initialize until needed
    set -gx PATH /opt/miniconda3/bin $PATH
    
    # Create a wrapper function that initializes conda on first use
    function conda
        functions --erase conda  # Remove this wrapper
        eval /opt/miniconda3/bin/conda "shell.fish" "hook" $argv | source
        conda $argv  # Call the real conda with original arguments
    end
end
# <<< conda initialize <<<

# Homebrew
if test -x /opt/homebrew/bin/brew
    set -gx HOMEBREW_PREFIX "/opt/homebrew"
    set -gx HOMEBREW_CELLAR "/opt/homebrew/Cellar"
    set -gx HOMEBREW_REPOSITORY "/opt/homebrew"
    set -gx PATH "/opt/homebrew/bin" "/opt/homebrew/sbin" $PATH
    set -gx MANPATH "/opt/homebrew/share/man" $MANPATH
    set -gx INFOPATH "/opt/homebrew/share/info" $INFOPATH
end

set -gx BUN_INSTALL $HOME/.bun
set -g PATH $BUN_INSTALL/bin $PATH

# starship init fish | source

# OPTIMIZED: Lazy-load zoxide - initialize on first use
if type -q zoxide
    # Create wrapper functions that initialize zoxide on first use
    function __zoxide_lazy_init
        functions --erase __zoxide_lazy_init z zi
        zoxide init fish | source
    end

    function z
        __zoxide_lazy_init
        z $argv
    end

    function zi
        __zoxide_lazy_init
        zi $argv
    end
end
