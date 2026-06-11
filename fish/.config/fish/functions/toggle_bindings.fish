function toggle_bindings
    if test "$fish_key_bindings" = fish_vi_key_bindings
        fish_default_key_bindings
    else
        fish_vi_key_bindings
    end
    commandline -f repaint
end
