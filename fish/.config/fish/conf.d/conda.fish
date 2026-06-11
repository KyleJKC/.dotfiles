# =============================================================================
# conda — lazy-loaded
# =============================================================================
# `conda shell.fish hook` is ~80ms and was previously run on EVERY shell start.
# Here it only runs the first time you actually call `conda`, halving startup.
if test -f /opt/miniconda3/bin/conda
    function conda --description 'Lazy-init conda, then run the real command'
        functions -e conda
        # NOTE: only the hook is eval'd — conda's own args must NOT leak into it.
        eval /opt/miniconda3/bin/conda shell.fish hook | source
        conda $argv
    end
else if test -f "/opt/miniconda3/etc/fish/conf.d/conda.fish"
    source "/opt/miniconda3/etc/fish/conf.d/conda.fish"
else if test -d /opt/miniconda3/bin
    fish_add_path /opt/miniconda3/bin
end
