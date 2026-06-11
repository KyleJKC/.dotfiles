# =============================================================================
# zoxide — lazy-loaded
# =============================================================================
# `zoxide init` is only run the first time you call z/zi, keeping startup fast.
if type -q zoxide
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
