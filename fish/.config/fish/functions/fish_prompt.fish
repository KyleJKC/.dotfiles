# Default appearance options. Override in config.fish if you want.
if ! set -q lucid_dirty_indicator
    set -g lucid_dirty_indicator "*"
end

if ! set -q lucid_prompt_symbol
    set -g lucid_prompt_symbol "λ"
end

if ! set -q lucid_prompt_symbol_error
    set -g lucid_prompt_symbol_error "λ"
end

if ! set -q lucid_prompt_symbol_color
    set -g lucid_prompt_symbol_color "9ccfd8"
end

if ! set -q lucid_prompt_symbol_error_color
    set -g lucid_prompt_symbol_error_color "eb6f92"
end

# This should be set to be at least as long as lucid_dirty_indicator, due to a fish bug
if ! set -q lucid_clean_indicator
    set -g lucid_clean_indicator (string replace -r -a '.' ' ' $lucid_dirty_indicator)
end

if ! set -q lucid_cwd_color
    set -g lucid_cwd_color cyan
end

if ! set -q lucid_git_color
    set -g lucid_git_color magenta
end

if ! set -q lucid_git_icon
    set -g lucid_git_icon ""
end

# OS-specific icons (you can customize these)
if ! set -q lucid_os_icons
    set -g lucid_os_icons
end

if ! set -q lucid_ssh_color
    set -g lucid_ssh_color yellow
end

# Cache for OS detection to avoid repeated uname calls
set -g __lucid_os_icon ""

# Skip newline on first prompt
set -g lucid_skip_newline 1

# State used for memoization and async calls.
set -g __lucid_cmd_id 0
set -g __lucid_git_state_cmd_id -1
set -g __lucid_git_static ""
set -g __lucid_dirty ""
set -g __lucid_last_prompt_cmd_id -1
set -g __lucid_should_skip_newline 0

# Increment a counter each time a prompt is about to be displayed.
# Enables us to distingish between redraw requests and new prompts.
function __lucid_increment_cmd_id --on-event fish_prompt
    set __lucid_cmd_id (math $__lucid_cmd_id + 1)
end

# Detect OS and return appropriate icon
function __lucid_get_os_icon
    # Return cached result if available
    if test -n "$__lucid_os_icon"
        echo $__lucid_os_icon
        return
    end

    # Detect OS using uname
    set -l os (uname -s 2>/dev/null)
    if test $status -ne 0
        set -g __lucid_os_icon "🌐"  # fallback
        echo $__lucid_os_icon
        return
    end

    # Map OS to icon (you can customize these mappings)
    switch $os
        case "Alpaquita"
            set -g __lucid_os_icon ""
        case "Alpine"
            set -g __lucid_os_icon ""
        case "AlmaLinux"
            set -g __lucid_os_icon ""
        case "Amazon"
            set -g __lucid_os_icon ""
        case "Android"
            set -g __lucid_os_icon ""
        case "AOSC"
            set -g __lucid_os_icon ""
        case "Arch"
            set -g __lucid_os_icon ""
        case "Artix"
            set -g __lucid_os_icon ""
        case "CachyOS"
            set -g __lucid_os_icon ""
        case "CentOS"
            set -g __lucid_os_icon ""
        case "Debian"
            set -g __lucid_os_icon ""
        case "DragonFly"
            set -g __lucid_os_icon ""
        case "Emscripten"
            set -g __lucid_os_icon ""
        case "EndeavourOS"
            set -g __lucid_os_icon ""
        case "Fedora"
            set -g __lucid_os_icon ""
        case "FreeBSD"
            set -g __lucid_os_icon ""
        case "Garuda"
            set -g __lucid_os_icon "󰛓"
        case "Gentoo"
            set -g __lucid_os_icon ""
        case "HardenedBSD"
            set -g __lucid_os_icon "󰞌"
        case "Illumos"
            set -g __lucid_os_icon "󰈸"
        case "Kali"
            set -g __lucid_os_icon ""
        case "Linux"
            set -g __lucid_os_icon ""
        case "Mabox"
            set -g __lucid_os_icon ""
        case "Darwin" "Macos"
            set -g __lucid_os_icon ""
        case "Manjaro"
            set -g __lucid_os_icon ""
        case "Mariner"
            set -g __lucid_os_icon ""
        case "MidnightBSD"
            set -g __lucid_os_icon ""
        case "Mint"
            set -g __lucid_os_icon ""
        case "NetBSD"
            set -g __lucid_os_icon ""
        case "NixOS"
            set -g __lucid_os_icon ""
        case "Nobara"
            set -g __lucid_os_icon ""
        case "OpenBSD"
            set -g __lucid_os_icon "󰈺"
        case "openSUSE"
            set -g __lucid_os_icon ""
        case "OracleLinux"
            set -g __lucid_os_icon "󰌷"
        case "Pop"
            set -g __lucid_os_icon ""
        case "Raspbian"
            set -g __lucid_os_icon ""
        case "Redhat"
            set -g __lucid_os_icon ""
        case "RedHatEnterprise"
            set -g __lucid_os_icon ""
        case "RockyLinux"
            set -g __lucid_os_icon ""
        case "Redox"
            set -g __lucid_os_icon "󰀘"
        case "Solus"
            set -g __lucid_os_icon "󰠳"
        case "SUSE"
            set -g __lucid_os_icon ""
        case "Ubuntu"
            set -g __lucid_os_icon ""
        case "Void"
            set -g __lucid_os_icon ""
        case "CYGWIN*" "MSYS*" "MINGW*" "Windows"
            set -g __lucid_os_icon "󰍲"
        case "Unknown" "*"
            set -g __lucid_os_icon ""
    end

    echo $__lucid_os_icon
end

# Abort an in-flight dirty check, if any.
function __lucid_abort_check
    if set -q __lucid_check_pid
        set -l pid $__lucid_check_pid
        functions -e __lucid_on_finish_$pid
        command kill $pid >/dev/null 2>&1
        set -e __lucid_check_pid
    end
end

function __lucid_git_status
    # Reset state if this call is *not* due to a redraw request
    set -l prev_dirty $__lucid_dirty
    if test $__lucid_cmd_id -ne $__lucid_git_state_cmd_id
        __lucid_abort_check

        set __lucid_git_state_cmd_id $__lucid_cmd_id
        set __lucid_git_static ""
        set __lucid_dirty ""
    end

    # Fetch git position & action synchronously.
    # Memoize results to avoid recomputation on subsequent redraws.
    if test -z $__lucid_git_static
        # Determine git working directory
        set -l git_dir (command git --no-optional-locks rev-parse --absolute-git-dir 2>/dev/null)
        if test $status -ne 0
            return 1
        end

        set -l position (command git --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
        if test $status -ne 0
            # Denote detached HEAD state with short commit hash
            set position (command git --no-optional-locks rev-parse --short HEAD 2>/dev/null)
            if test $status -eq 0
                set position "@$position"
            end
        end

        # TODO: add bisect
        set -l action ""
        if test -f "$git_dir/MERGE_HEAD"
            set action "merge"
        else if test -d "$git_dir/rebase-merge"
            set action "rebase"
        else if test -d "$git_dir/rebase-apply"
            set action "rebase"
        end

        set -l state $position
        if test -n $action
            set state "$state <$action>"
        end

        set -g __lucid_git_static $state
    end

    # Fetch dirty status asynchronously.
    if test -z $__lucid_dirty
        if ! set -q __lucid_check_pid
            # Compose shell command to run in background
            # OPTIMIZED: Use simpler git command with early exit
            set -l check_cmd "git --no-optional-locks status --porcelain --ignore-submodules=all 2>/dev/null | read -n 1"
            set -l cmd "if $check_cmd; exit 1; else; exit 0; end"

            begin
                # Defer execution of event handlers by fish for the remainder of lexical scope.
                # This is to prevent a race between the child process exiting before we can get set up.
                block -l

                set -g __lucid_check_pid 0
                command fish --private --command "$cmd" >/dev/null 2>&1 &
                set -l pid (jobs --last --pid)

                set -g __lucid_check_pid $pid

                # Use exit code to convey dirty status to parent process.
                function __lucid_on_finish_$pid --inherit-variable pid --on-process-exit $pid
                    functions -e __lucid_on_finish_$pid

                    if set -q __lucid_check_pid
                        if test $pid -eq $__lucid_check_pid
                            switch $argv[3]
                                case 0
                                    set -g __lucid_dirty_state 0
                                    if status is-interactive
                                        commandline -f repaint
                                    end
                                case 1
                                    set -g __lucid_dirty_state 1
                                    if status is-interactive
                                        commandline -f repaint
                                    end
                                case '*'
                                    set -g __lucid_dirty_state 2
                                    if status is-interactive
                                        commandline -f repaint
                                    end
                            end
                        end
                    end
                end
            end
        end

        if set -q __lucid_dirty_state
            switch $__lucid_dirty_state
                case 0
                    set -g __lucid_dirty $lucid_clean_indicator
                case 1
                    set -g __lucid_dirty $lucid_dirty_indicator
                case 2
                    set -g __lucid_dirty "<err>"
            end

            set -e __lucid_check_pid
            set -e __lucid_dirty_state
        end
    end

    # Render git status. When in-progress, use previous state to reduce flicker.
    set_color $lucid_git_color
    echo -n $lucid_git_icon $__lucid_git_static ''

    if ! test -z $__lucid_dirty
        echo -n $__lucid_dirty
    else if ! test -z $prev_dirty
        set_color --dim $lucid_git_color
        echo -n $prev_dirty
        set_color normal
    end

    set_color normal
end

function __lucid_vi_indicator
    if [ $fish_key_bindings = "fish_vi_key_bindings" ]
        switch $fish_bind_mode
            case "insert"
                set_color green
                echo -n "[I] "
            case "default"
                set_color red
                echo -n "[N] "
            case "visual"
                set_color yellow
                echo -n "[S] "
            case "replace"
                set_color blue
                echo -n "[R] "
        end
        set_color normal
    end
end

# Suppress default mode prompt
function fish_mode_prompt
end

# Wrapper functions to skip newline after clearing screen
function clear --description 'Clear the screen and skip newline on next prompt'
    set -g lucid_skip_newline 1
    command clear $argv
end

function reset --description 'Reset the terminal and skip newline on next prompt'
    set -g lucid_skip_newline 1
    command reset $argv
end

function fish_prompt
    set -l last_pipestatus $pipestatus
    # OPTIMIZED: Use prompt_pwd which is faster and handles ~ replacement
    set -l cwd (prompt_pwd)

    # On a new prompt (not a repaint), decide whether to skip the newline
    if test $__lucid_cmd_id -ne $__lucid_last_prompt_cmd_id
        set -g __lucid_last_prompt_cmd_id $__lucid_cmd_id

        # Store the decision: should we skip newline for this prompt?
        if set -q lucid_skip_newline
            set -g __lucid_should_skip_newline 1
            set -e lucid_skip_newline
        else
            set -g __lucid_should_skip_newline 0
        end
    end

    # Apply the decision on every render (including repaints)
    if test $__lucid_should_skip_newline -eq 0
        echo ''
    end

    set_color $lucid_cwd_color --bold
    echo -sn $cwd
    set_color normal

    if test $cwd != '~'; or test -n "$lucid_git_status_in_home_directory"
        set -l git_state (__lucid_git_status)
        if test $status -eq 0
            echo -sn " on $git_state"
        end
    end

    # Display SSH info on the right side of the first line
    if set -q SSH_CONNECTION
        set -l os_icon (__lucid_get_os_icon)
        set -l ssh_info "$os_icon $USER@"(hostname -s)
        # Calculate length of visible characters (strip ANSI codes for length calculation)
        set -l ssh_info_length (string length -- $ssh_info)
        # Move cursor to the right position and print
        # Use tput to move cursor: save position, move to column, restore
        echo -n (tput sc) # Save cursor position
        echo -n (tput hpa (math $COLUMNS - $ssh_info_length)) # Move to calculated column
        set_color $lucid_ssh_color
        echo -n $ssh_info
        set_color normal
        echo -n (tput rc) # Restore cursor position
    end

    echo ''
    __lucid_vi_indicator

    set -l prompt_symbol "$lucid_prompt_symbol"
    set -l prompt_symbol_color "$lucid_prompt_symbol_color"

    # OPTIMIZED: Check first status only (most common case)
    if test "$last_pipestatus[-1]" -ne 0
        set prompt_symbol "$lucid_prompt_symbol_error"
        set prompt_symbol_color "$lucid_prompt_symbol_error_color"
    end

    set_color "$prompt_symbol_color" --bold
    echo -n "$prompt_symbol "
    set_color normal
end