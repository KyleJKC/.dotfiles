function prepend_sudo --description 'Toggle `sudo` at the start of the command line (Esc Esc)'
    set -l cmd (commandline)

    # If the line is empty, operate on the most recent command (like zsh's plugin)
    if test -z "$cmd"
        set cmd $history[1]
    end

    if string match -q -- 'sudo *' $cmd
        # Already prefixed — strip it (toggle off)
        commandline -r (string replace -r -- '^sudo ' '' $cmd)
    else
        commandline -r "sudo $cmd"
    end
    commandline -f end-of-line
end
