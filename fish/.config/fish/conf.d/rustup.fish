# Cargo — just add to PATH (idempotent via fish_add_path), no full env init
if test -d "$HOME/.cargo/bin"
    fish_add_path $HOME/.cargo/bin
end
