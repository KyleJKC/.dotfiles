# =============================================================================
# config.fish
# =============================================================================
# Only bootstrap + order-sensitive interactive setup lives here.
# Everything else is modularized under conf.d/ (auto-sourced BEFORE this file):
#   conf.d/aliases.fish   – shell aliases
#   conf.d/paths.fish     – PATH / Homebrew / Bun
#   conf.d/env.fish       – environment vars (EDITOR, FZF, bat, …)
#   conf.d/zoxide.fish    – lazy-loaded zoxide
#   conf.d/conda.fish     – lazy-loaded conda
#   conf.d/rustup.fish    – cargo path
# =============================================================================

# Bootstrap fisher (plugin manager) on first interactive launch
if status is-interactive
    if not functions -q fisher
        echo "⏳ Installing fisher..."
        curl --silent --location https://git.io/fisher | source
        and fisher update
    end
end

if status is-interactive
    # FZF bindings — must run AFTER conf.d/fzf.fish (the plugin), which installs
    # default bindings during the conf.d phase. config.fish runs after conf.d,
    # so this is where our custom --directory override wins.
    fzf_configure_bindings --directory=\cf

    # Toggle key bindings (Ctrl-O) — kept here so it applies after fish has
    # initialized its default key bindings.
    bind \co toggle_bindings
    bind -M insert \co toggle_bindings

    # Esc-Esc → toggle `sudo` at the start of the line (zsh sudo-plugin muscle memory).
    # fish 4.x: two Escape presses are the `escape,escape` key sequence — NOT
    # `alt-escape` (legacy `\e\e`, which never fires from a double-tap).
    # Bound ONLY in `default` mode (= vi normal mode), deliberately NOT in insert
    # mode: an insert-mode sequence would make every Esc-to-leave-insert wait
    # fish_sequence_key_delay_ms for a possible second Esc. So: Esc exits insert
    # instantly, then Esc-Esc in normal mode prepends sudo.
    bind escape,escape prepend_sudo
end
