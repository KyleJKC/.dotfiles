# =============================================================================
# PATH management
# =============================================================================
# fish_add_path is idempotent (dedupes via the universal fish_user_paths var),
# so re-running this never duplicates entries — unlike a bare `set PATH ...`.

# Homebrew (manual shellenv — avoids the ~slow `brew shellenv` subprocess)
if test -x /opt/homebrew/bin/brew
    set -gx HOMEBREW_PREFIX /opt/homebrew
    set -gx HOMEBREW_CELLAR /opt/homebrew/Cellar
    set -gx HOMEBREW_REPOSITORY /opt/homebrew
    fish_add_path /opt/homebrew/bin /opt/homebrew/sbin
    set -gx MANPATH /opt/homebrew/share/man $MANPATH
    set -gx INFOPATH /opt/homebrew/share/info $INFOPATH
end

# Bun
set -gx BUN_INSTALL $HOME/.bun
fish_add_path $HOME/.bun/bin

# Claude Code / user-local binaries
fish_add_path $HOME/.local/bin
