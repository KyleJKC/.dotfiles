# ███████╗███████╗██╗  ██╗██████╗  ██████╗
# ╚══███╔╝██╔════╝██║  ██║██╔══██╗██╔════╝
#   ███╔╝ ███████╗███████║██████╔╝██║     
#  ███╔╝  ╚════██║██╔══██║██╔══██╗██║     
# ███████╗███████║██║  ██║██║  ██║╚██████╗
# ╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝
# By KyleJKC


# Module
# module_path+=( "/Users/kylejin/.local/share/zinit/module/Src" )
# zmodload zdharma_continuum/zinit

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Options
setopt auto_cd

# Alias
alias c='clear'
alias ls='lsd --group-directories-first' # Make sure you installed lsd
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
alias reload='source ~/.zshrc'
alias lg='lazygit'
alias proxy='export all_proxy=socks5://127.0.0.1:1080'
alias unproxy='unset all_proxy'
alias ss='sslocal -c /etc/shadowsocks/config.json -d'
alias killss='killall sslocal'

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/opt/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/opt/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# FZF
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Zoxide
eval "$(zoxide init zsh)"

### Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust

### End of Zinit's installer chunk

# Theme
zinit ice depth=1
zinit light romkatv/powerlevel10k

# OMZ Libraries & Plugins
zinit for \
      OMZL::{'history','completion','git','grep','key-bindings'}.zsh

zinit wait lucid for \
      OMZP::{'colored-man-pages','extract','fzf','git','sudo'}

# Plugins
zinit ice depth=1 wait"2" lucid
zinit light hlissner/zsh-autopair

zinit wait lucid for \
      atinit"ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay" \
        zdharma-continuum/fast-syntax-highlighting \
      blockf \
        zsh-users/zsh-completions \
      atload"!_zsh_autosuggest_start" \
        zsh-users/zsh-autosuggestions

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
