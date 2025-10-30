# ~/.config/fish/functions/fish_prompt.fish
#
# A sophisticated, feature-rich Fish shell prompt with the following capabilities:
# - Customizable colors and symbols for different prompt elements
# - Git repository status with background dirty checking for performance
# - OS/distribution detection with appropriate icons
# - SSH connection detection and display
# - Vi mode indicator for fish_vi_key_bindings
# - Smart newline control (skip after clear/reset commands)
# - Two-line layout with left/right alignment and responsive wrapping
# - Error state indication with different colors/symbols
# - Background process management to prevent blocking the prompt
#
# This prompt is designed to be both visually appealing and highly functional,
# providing essential information at a glance while maintaining good performance.

# =============================================================================
# CONFIGURATION VARIABLES
# =============================================================================
# These variables allow users to customize the prompt appearance and behavior.
# Each variable is set with a default value if not already defined by the user.

# ------- Configuration Variables -------
# Git repository status indicators
if ! set -q lucid_dirty_indicator
    set -g lucid_dirty_indicator "*"  # Symbol shown when git repo has uncommitted changes
end
# Main prompt symbols (lambda character by default)
if ! set -q lucid_prompt_symbol
    set -g lucid_prompt_symbol "λ"  # Normal prompt symbol
end
if ! set -q lucid_prompt_symbol_error
    set -g lucid_prompt_symbol_error "λ"  # Symbol when last command failed
end
# Color schemes for prompt elements (hex colors for better terminal compatibility)
if ! set -q lucid_prompt_symbol_color
    set -g lucid_prompt_symbol_color "9ccfd8"  # Light blue for normal prompt
end
if ! set -q lucid_prompt_symbol_error_color
    set -g lucid_prompt_symbol_error_color "eb6f92"  # Pink for error prompt
end
# Clean indicator should be same length as dirty indicator due to fish bug
# Uses spaces to match the length of the dirty indicator
if ! set -q lucid_clean_indicator
    set -g lucid_clean_indicator (string replace -r -a '.' ' ' $lucid_dirty_indicator)
end
if ! set -q lucid_cwd_color
    set -g lucid_cwd_color cyan  # Color for current working directory
end
if ! set -q lucid_git_color
    set -g lucid_git_color magenta  # Color for git branch/status information
end

# Git and OS display elements
if ! set -q lucid_git_icon
    set -g lucid_git_icon ""
end
if ! set -q lucid_os_icons
    set -g lucid_os_icons  # OS-specific icons (empty by default, populated by detection)
end
if ! set -q lucid_ssh_color
    set -g lucid_ssh_color yellow  # Color for SSH connection indicator
end

# =============================================================================
# INTERNAL STATE VARIABLES
# =============================================================================
# These variables maintain the prompt's internal state and are used for
# caching, performance optimization, and state tracking across prompt renders.

# ------- Internal state -------
set -g __lucid_os_icon ""  # Cached OS icon to avoid repeated detection
set -g lucid_skip_newline 1  # Flag to skip newline after clear/reset commands
set -g __lucid_cmd_id 0  # Counter for tracking command execution order
set -g __lucid_git_state_cmd_id -1  # ID of last command that updated git state
set -g __lucid_git_static ""  # Cached git branch/status information
set -g __lucid_dirty ""  # Cached git dirty/clean status
set -g __lucid_last_prompt_cmd_id -1  # ID of last command that rendered prompt
set -g __lucid_should_skip_newline 0  # Internal flag for newline control

# =============================================================================
# EVENT HANDLERS
# =============================================================================
# These functions are triggered by Fish shell events to maintain prompt state.

# ------- Event hook to track prompt renders -------
# Increments the command ID counter each time the prompt is rendered.
# This helps track when git status needs to be refreshed and prevents
# unnecessary background processes from running.
function __lucid_increment_cmd_id --on-event fish_prompt
    set __lucid_cmd_id (math $__lucid_cmd_id + 1)
end

# =============================================================================
# OS DETECTION AND ICON MANAGEMENT
# =============================================================================
# Detects the operating system/distribution and returns an appropriate icon.
# Uses a combination of /etc/os-release parsing and uname for maximum compatibility.

# ------- Distro/OS-aware icon detection -------
# Returns a cached OS icon or detects and caches a new one.
# Supports a wide range of Linux distributions, BSD variants, macOS, and Windows.
function __lucid_get_os_icon
    # Return cached icon if available to avoid repeated detection
    if test -n "$__lucid_os_icon"
        echo $__lucid_os_icon
        return
    end

    # Try to detect distro or OS using multiple methods
    set -l id ""
    set -l uname (uname -s 2>/dev/null)

    # Parse /etc/os-release for Linux distributions
    if test -r /etc/os-release
        set id (string lower (string replace -r '^ID="?([^"]+)"?$' '$1' -- (string match -r '^ID=.*' < /etc/os-release)))
    end

    # On FreeBSD (and other BSDs), prefer uname, ignore /etc/os-release
    # BSD systems have different release file structures
    switch $uname
        case FreeBSD DragonFly OpenBSD NetBSD
            switch $uname
                case FreeBSD;    set -g __lucid_os_icon ""
                case DragonFly;  set -g __lucid_os_icon ""
                case OpenBSD;    set -g __lucid_os_icon "󰈺"
                case NetBSD;     set -g __lucid_os_icon ""
            end
            echo $__lucid_os_icon
            return
    end

    # Linux / macOS / Windows and others
    # Match against known distribution IDs from /etc/os-release
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
        case macos darwin; set -g __lucid_os_icon ""
        case '*'
            # Fallback to uname-based detection for unknown distributions
            switch $uname
                case CYGWIN* MSYS* MINGW* Windows; set -g __lucid_os_icon "󰍲"  # Windows icon
                case Darwin; set -g __lucid_os_icon ""  # macOS icon (fallback)
                case Linux;  set -g __lucid_os_icon ""  # Generic Linux icon
                case '*';    set -g __lucid_os_icon ""  # Unknown OS icon
            end
    end

    echo $__lucid_os_icon
end

# =============================================================================
# SSH DETECTION
# =============================================================================
# Detects if the current session is running over SSH.

# ------- Helper: "am I over SSH?" (robust across tmux/screen) -------
# Checks multiple SSH environment variables to detect SSH connections.
# Works reliably even when running inside tmux or screen sessions.
function __lucid_is_ssh
    if set -q SSH_CONNECTION; or set -q SSH_CLIENT; or set -q SSH_TTY
        return 0  # SSH connection detected
    end
    return 1  # Not an SSH connection
end

# =============================================================================
# GIT STATUS MANAGEMENT
# =============================================================================
# Handles git repository status detection with background processing for performance.
# Uses background processes to avoid blocking the prompt during git operations.

# ------- Backgroundable git status (your original logic, trimmed slightly) -------
# Aborts any running git status check process to prevent resource leaks.
# Called when starting a new git status check or when the prompt is refreshed.
function __lucid_abort_check
    if set -q __lucid_check_pid
        set -l pid $__lucid_check_pid
        functions -e __lucid_on_finish_$pid  # Remove the callback function
        command kill $pid >/dev/null 2>&1  # Kill the background process
        set -e __lucid_check_pid  # Clear the PID variable
    end
end

# Main git status function that handles both static info (branch) and dynamic info (dirty state).
# Uses background processes for dirty checking to avoid blocking the prompt.
function __lucid_git_status
    set -l prev_dirty $__lucid_dirty
    # Check if we need to refresh git state (new command since last update)
    if test $__lucid_cmd_id -ne $__lucid_git_state_cmd_id
        __lucid_abort_check  # Kill any existing background process
        set __lucid_git_state_cmd_id $__lucid_cmd_id
        set __lucid_git_static ""  # Clear cached static info
        set __lucid_dirty ""  # Clear cached dirty state
    end

    # Get static git information (branch name, merge/rebase state) if not cached
    if test -z $__lucid_git_static
        # Find the git directory
        set -l git_dir (command git --no-optional-locks rev-parse --absolute-git-dir 2>/dev/null)
        if test $status -ne 0
            return 1  # Not a git repository
        end

        # Get branch name or commit hash
        set -l position (command git --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
        if test $status -ne 0
            # If no branch name, use short commit hash with @ prefix
            set position (command git --no-optional-locks rev-parse --short HEAD 2>/dev/null)
            if test $status -eq 0
                set position "@$position"
            end
        end

        # Check for ongoing merge or rebase operations
        set -l action ""
        if test -f "$git_dir/MERGE_HEAD"
            set action "merge"
        else if test -d "$git_dir/rebase-merge"; or test -d "$git_dir/rebase-apply"
            set action "rebase"
        end

        # Combine position and action into final state string
        set -l state $position
        if test -n "$action"
            set state "$state <$action>"
        end
        set -g __lucid_git_static $state
    end

    # Check dirty state using background process if not already cached
    if test -z $__lucid_dirty
        if ! set -q __lucid_check_pid
            # Create command to check if git has uncommitted changes
            set -l check_cmd "git --no-optional-locks status --porcelain --ignore-submodules=all 2>/dev/null | read -n 1"
            set -l cmd "if $check_cmd; exit 1; else; exit 0; end"

            # Start background process to check git status
            block -l
            set -g __lucid_check_pid 0
            command fish --private --command "$cmd" >/dev/null 2>&1 &
            set -l pid (jobs --last --pid)
            set -g __lucid_check_pid $pid

            # Set up callback function to handle process completion
            function __lucid_on_finish_$pid --inherit-variable pid --on-process-exit $pid
                functions -e __lucid_on_finish_$pid
                if set -q __lucid_check_pid; and test $pid -eq $__lucid_check_pid
                    # Map exit codes to dirty states
                    switch $argv[3]
                        case 0; set -g __lucid_dirty_state 0  # Clean (no output from git status)
                        case 1; set -g __lucid_dirty_state 1  # Dirty (has uncommitted changes)
                        case '*'; set -g __lucid_dirty_state 2  # Error
                    end
                    # Trigger prompt repaint if in interactive mode
                    if status is-interactive
                        commandline -f repaint
                    end
                end
            end
        end

        # Process the result when background check completes
        if set -q __lucid_dirty_state
            switch $__lucid_dirty_state
                case 0; set -g __lucid_dirty $lucid_clean_indicator  # Clean indicator
                case 1; set -g __lucid_dirty $lucid_dirty_indicator  # Dirty indicator
                case 2; set -g __lucid_dirty "<err>"  # Error indicator
            end
            set -e __lucid_check_pid
            set -e __lucid_dirty_state
        end
    end

    # Output the git status with appropriate colors
    set_color $lucid_git_color
    echo -n $lucid_git_icon $__lucid_git_static ''
    if test -n "$__lucid_dirty"
        # Show current dirty state
        echo -n $__lucid_dirty
    else if test -n "$prev_dirty"
        # Show previous dirty state dimmed while waiting for new result
        set_color --dim $lucid_git_color
        echo -n $prev_dirty
        set_color normal
    end
    set_color normal
end

# =============================================================================
# VI MODE INDICATOR
# =============================================================================
# Displays the current vi mode when using fish_vi_key_bindings.

# ------- Mode indicator (unchanged) -------
# Shows the current vi mode with color-coded indicators
function __lucid_vi_indicator
    if [ $fish_key_bindings = "fish_vi_key_bindings" ]
        switch $fish_bind_mode
            case insert;  set_color green;  echo -n "[I] "  # Insert mode
            case default; set_color red;    echo -n "[N] "  # Normal mode
            case visual;  set_color yellow; echo -n "[S] "  # Visual/Select mode
            case replace; set_color blue;   echo -n "[R] "  # Replace mode
        end
        set_color normal
    end
end
# Disable fish's default mode prompt since we handle it ourselves
function fish_mode_prompt; end

# =============================================================================
# CONVENIENCE FUNCTIONS
# =============================================================================
# Wrapper functions that provide enhanced behavior for common commands.

# Convenience wrappers to skip newline after clear/reset
# These prevent the prompt from adding an extra newline after clearing the screen
function clear --description 'Clear the screen and skip newline on next prompt'
    set -g lucid_skip_newline 1
    command clear $argv
end
function reset --description 'Reset the terminal and skip newline on next prompt'
    set -g lucid_skip_newline 1
    command reset $argv
end

# =============================================================================
# LAYOUT MANAGEMENT
# =============================================================================
# Handles the two-line prompt layout with left/right alignment and responsive wrapping.

# ------- Single-line left/right layout without cursor gymnastics -------
# Prints left and right content with proper spacing and responsive wrapping.
# Arguments: left_plain, left_colored, right_plain, right_colored
function __lucid_print_left_right --argument-names left_plain left_colored right_plain right_colored
    # Get terminal width with fallback to 80 columns
    set -l cols (tput cols 2>/dev/null); or set -q COLUMNS; and set cols $COLUMNS; or set cols 80

    # Calculate visible lengths (ignoring color escape sequences)
    set -l l (string length --visible -- $left_plain)
    set -l r (string length --visible -- $right_plain)

    # Calculate if content fits on one line
    set -l min_gap 1
    set -l needed (math "$l + $r + $min_gap")

    if test $needed -gt $cols
        # Too narrow: put right segment on next line
        echo -sn $left_colored
        echo
        echo -sn $right_colored
    else
        # Fit on one line with appropriate spacing
        set -l gap (math "max(1, $cols - $l - $r - 1)")
        echo -sn $left_colored (string repeat -n $gap " ") $right_colored
    end
end

# =============================================================================
# MAIN PROMPT FUNCTION
# =============================================================================
# The main fish_prompt function that orchestrates the entire prompt display.
# Handles newline control, git status, SSH detection, and two-line layout.

# ------- The prompt -------
function fish_prompt
    # Store the exit status of the last command for error indication
    set -l last_pipestatus $pipestatus
    # Get the current working directory (abbreviated)
    set -l cwd (prompt_pwd)

    # Handle newline control for clear/reset commands
    if test $__lucid_cmd_id -ne $__lucid_last_prompt_cmd_id
        set -g __lucid_last_prompt_cmd_id $__lucid_cmd_id
        if set -q lucid_skip_newline
            set -g __lucid_should_skip_newline 1
            set -e lucid_skip_newline
        else
            set -g __lucid_should_skip_newline 0
        end
    end
    # Print newline unless we're skipping it (after clear/reset)
    if test $__lucid_should_skip_newline -eq 0
        echo ''
    end

    # Get git repository status (skip in home directory unless explicitly enabled)
    set -l git_state ""
    if test $cwd != '~'; or test -n "$lucid_git_status_in_home_directory"
        set git_state (__lucid_git_status)
        if test $status -ne 0
            set git_state ""  # Clear git state if not in a git repo
        end
    end

    # Build left side content (directory + git status)
    set -l left_plain $cwd
    if test -n "$git_state"
        set left_plain "$left_plain on $git_state"
    end

    # Create colored version of left content
    set -l left_colored ""
    set left_colored (set_color $lucid_cwd_color --bold; echo -n $cwd; set_color normal)
    if test -n "$git_state"
        set left_colored "$left_colored on "(set_color $lucid_git_color; echo -n $git_state; set_color normal)
    end

    # Build right side content (SSH connection info with OS icon)
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

    # Second line: vi mode indicator + prompt symbol
    __lucid_vi_indicator

    # Choose prompt symbol and color based on command success/failure
    set -l prompt_symbol "$lucid_prompt_symbol"
    set -l prompt_symbol_color "$lucid_prompt_symbol_color"
    if test "$last_pipestatus[-1]" -ne 0
        # Use error symbol and color if last command failed
        set prompt_symbol "$lucid_prompt_symbol_error"
        set prompt_symbol_color "$lucid_prompt_symbol_error_color"
    end

    # Display the prompt symbol with appropriate color
    set_color "$prompt_symbol_color" --bold
    echo -n "$prompt_symbol "
    set_color normal
end