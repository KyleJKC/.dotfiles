# ~/.config/fish/functions/fish_prompt.fish

# ------- Config knobs (same defaults you used) -------
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
# This should be at least as long as lucid_dirty_indicator, due to a fish bug
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
if ! set -q lucid_os_icons
    set -g lucid_os_icons
end
if ! set -q lucid_ssh_color
    set -g lucid_ssh_color yellow
end

# ------- Internal state -------
set -g __lucid_os_icon ""
set -g lucid_skip_newline 1
set -g __lucid_cmd_id 0
set -g __lucid_git_state_cmd_id -1
set -g __lucid_git_static ""
set -g __lucid_dirty ""
set -g __lucid_last_prompt_cmd_id -1
set -g __lucid_should_skip_newline 0

# ------- Event hook to track prompt renders -------
function __lucid_increment_cmd_id --on-event fish_prompt
    set __lucid_cmd_id (math $__lucid_cmd_id + 1)
end

# ------- Distro/OS-aware icon detection -------
function __lucid_get_os_icon
    if test -n "$__lucid_os_icon"
        echo $__lucid_os_icon
        return
    end

    # Prefer /etc/os-release for Linux-like systems but skip on BSD
    if test -r /etc/os-release
        set -l id (string lower (string replace -r '^ID="?([^"]+)"?$' '$1' -- (string match -r '^ID=.*' < /etc/os-release)))
        # guard: if it's actually FreeBSD, defer to uname logic
        if test "$id" = freebsd
            set -l uname (uname -s)
        else
            set -l uname ""
        end
    end

    if test -z "$uname"
        switch $id
            case ubuntu;      set -g __lucid_os_icon ""
            case debian;      set -g __lucid_os_icon ""
            case arch;        set -g __lucid_os_icon ""
            case artix;       set -g __lucid_os_icon ""
            case fedora;      set -g __lucid_os_icon ""
            case 'opensuse*'; set -g __lucid_os_icon ""
            case nixos;       set -g __lucid_os_icon ""
            case manjaro;     set -g __lucid_os_icon ""
            case gentoo;      set -g __lucid_os_icon ""
            case pop;         set -g __lucid_os_icon ""
            case alpine;      set -g __lucid_os_icon ""
            case void;        set -g __lucid_os_icon ""
            case rocky;       set -g __lucid_os_icon ""
            case rhel redhat; set -g __lucid_os_icon ""
            case '*';         set -g __lucid_os_icon ""
        end
    else
        switch $uname
            case FreeBSD; set -g __lucid_os_icon ""
            case DragonFly; set -g __lucid_os_icon ""
            case OpenBSD; set -g __lucid_os_icon "󰈺"
            case NetBSD; set -g __lucid_os_icon ""
            case Darwin Macos; set -g __lucid_os_icon ""
            case CYGWIN* MSYS* MINGW* Windows; set -g __lucid_os_icon "󰍲"
            case Linux; set -g __lucid_os_icon ""
            case '*'; set -g __lucid_os_icon ""
        end
    end

    echo $__lucid_os_icon
end

# ------- Helper: “am I over SSH?” (robust across tmux/screen) -------
function __lucid_is_ssh
    if set -q SSH_CONNECTION; or set -q SSH_CLIENT; or set -q SSH_TTY
        return 0
    end
    return 1
end

# ------- Backgroundable git status (your original logic, trimmed slightly) -------
function __lucid_abort_check
    if set -q __lucid_check_pid
        set -l pid $__lucid_check_pid
        functions -e __lucid_on_finish_$pid
        command kill $pid >/dev/null 2>&1
        set -e __lucid_check_pid
    end
end

function __lucid_git_status
    set -l prev_dirty $__lucid_dirty
    if test $__lucid_cmd_id -ne $__lucid_git_state_cmd_id
        __lucid_abort_check
        set __lucid_git_state_cmd_id $__lucid_cmd_id
        set __lucid_git_static ""
        set __lucid_dirty ""
    end

    if test -z $__lucid_git_static
        set -l git_dir (command git --no-optional-locks rev-parse --absolute-git-dir 2>/dev/null)
        if test $status -ne 0
            return 1
        end

        set -l position (command git --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
        if test $status -ne 0
            set position (command git --no-optional-locks rev-parse --short HEAD 2>/dev/null)
            if test $status -eq 0
                set position "@$position"
            end
        end

        set -l action ""
        if test -f "$git_dir/MERGE_HEAD"
            set action "merge"
        else if test -d "$git_dir/rebase-merge"; or test -d "$git_dir/rebase-apply"
            set action "rebase"
        end

        set -l state $position
        if test -n "$action"
            set state "$state <$action>"
        end
        set -g __lucid_git_static $state
    end

    if test -z $__lucid_dirty
        if ! set -q __lucid_check_pid
            set -l check_cmd "git --no-optional-locks status --porcelain --ignore-submodules=all 2>/dev/null | read -n 1"
            set -l cmd "if $check_cmd; exit 1; else; exit 0; end"

            block -l
            set -g __lucid_check_pid 0
            command fish --private --command "$cmd" >/dev/null 2>&1 &
            set -l pid (jobs --last --pid)
            set -g __lucid_check_pid $pid

            function __lucid_on_finish_$pid --inherit-variable pid --on-process-exit $pid
                functions -e __lucid_on_finish_$pid
                if set -q __lucid_check_pid; and test $pid -eq $__lucid_check_pid
                    switch $argv[3]
                        case 0; set -g __lucid_dirty_state 0
                        case 1; set -g __lucid_dirty_state 1
                        case '*'; set -g __lucid_dirty_state 2
                    end
                    if status is-interactive
                        commandline -f repaint
                    end
                end
            end
        end

        if set -q __lucid_dirty_state
            switch $__lucid_dirty_state
                case 0; set -g __lucid_dirty $lucid_clean_indicator
                case 1; set -g __lucid_dirty $lucid_dirty_indicator
                case 2; set -g __lucid_dirty "<err>"
            end
            set -e __lucid_check_pid
            set -e __lucid_dirty_state
        end
    end

    set_color $lucid_git_color
    echo -n $lucid_git_icon $__lucid_git_static ''
    if test -n "$__lucid_dirty"
        echo -n $__lucid_dirty
    else if test -n "$prev_dirty"
        set_color --dim $lucid_git_color
        echo -n $prev_dirty
        set_color normal
    end
    set_color normal
end

# ------- Mode indicator (unchanged) -------
function __lucid_vi_indicator
    if [ $fish_key_bindings = "fish_vi_key_bindings" ]
        switch $fish_bind_mode
            case insert;  set_color green;  echo -n "[I] "
            case default; set_color red;    echo -n "[N] "
            case visual;  set_color yellow; echo -n "[S] "
            case replace; set_color blue;   echo -n "[R] "
        end
        set_color normal
    end
end
function fish_mode_prompt; end

# Convenience wrappers to skip newline after clear/reset
function clear --description 'Clear the screen and skip newline on next prompt'
    set -g lucid_skip_newline 1
    command clear $argv
end
function reset --description 'Reset the terminal and skip newline on next prompt'
    set -g lucid_skip_newline 1
    command reset $argv
end

# ------- Single-line left/right layout without cursor gymnastics -------
function __lucid_print_left_right --argument-names left_plain left_colored right_plain right_colored
    # Terminal width (robust): tput cols, then $COLUMNS, else 80
    set -l cols (tput cols 2>/dev/null); or set -q COLUMNS; and set cols $COLUMNS; or set cols 80

    # Visible lengths (no color escapes; decent with wide glyphs)
    set -l l (string length --visible -- $left_plain)
    set -l r (string length --visible -- $right_plain)

    set -l min_gap 1
    set -l needed (math "$l + $r + $min_gap")

    if test $needed -gt $cols
        # Too narrow: put right segment on next line
        echo -sn $left_colored
        echo
        echo -sn $right_colored
    else
	set -l gap (math "max(1, $cols - $l - $r - 1)")
        echo -sn $left_colored (string repeat -n $gap " ") $right_colored
    end
end

# ------- The prompt -------
function fish_prompt
    set -l last_pipestatus $pipestatus
    set -l cwd (prompt_pwd)

    # newline control per your original logic
    if test $__lucid_cmd_id -ne $__lucid_last_prompt_cmd_id
        set -g __lucid_last_prompt_cmd_id $__lucid_cmd_id
        if set -q lucid_skip_newline
            set -g __lucid_should_skip_newline 1
            set -e lucid_skip_newline
        else
            set -g __lucid_should_skip_newline 0
        end
    end
    if test $__lucid_should_skip_newline -eq 0
        echo ''
    end

    # Compute git state (if desired outside ~)
    set -l git_state ""
    if test $cwd != '~'; or test -n "$lucid_git_status_in_home_directory"
        set git_state (__lucid_git_status)
        if test $status -ne 0
            set git_state ""
        end
    end

    # Build left (plain + colored) for measuring and printing
    set -l left_plain $cwd
    if test -n "$git_state"
        set left_plain "$left_plain on $git_state"
    end

    set -l left_colored ""
    set left_colored (set_color $lucid_cwd_color --bold; echo -n $cwd; set_color normal)
    if test -n "$git_state"
	    set left_colored "$left_colored on "(set_color $lucid_git_color; echo -n $git_state; set_color normal)
    end

    # Build right (only if SSH)
    set -l right_plain ""
    set -l right_colored ""
    if __lucid_is_ssh
        set -l os_icon (__lucid_get_os_icon)
        set right_plain "$os_icon $USER@"(hostname -s)
        set right_colored (set_color $lucid_ssh_color; echo -n $right_plain; set_color normal)
    end

    # Print the first prompt line with left/right layout
    if test -n "$right_plain"
        __lucid_print_left_right "$left_plain" "$left_colored" "$right_plain" "$right_colored"
    else
        echo -sn $left_colored
    end

    echo ''  # newline after the top line

    # Second line: mode + prompt symbol (and error color if needed)
    __lucid_vi_indicator

    set -l prompt_symbol "$lucid_prompt_symbol"
    set -l prompt_symbol_color "$lucid_prompt_symbol_color"
    if test "$last_pipestatus[-1]" -ne 0
        set prompt_symbol "$lucid_prompt_symbol_error"
        set prompt_symbol_color "$lucid_prompt_symbol_error_color"
    end
    set_color "$prompt_symbol_color" --bold
    echo -n "$prompt_symbol "
    set_color normal
end

