# Shadow direnv's generated vendor hook with a built-in fast path. Outside an
# .envrc tree there is nothing to load or unload, so avoid launching direnv.
command -q direnv; or return

function __direnv_needs_export
    set -q DIRENV_DIR; and return 0

    set -l candidate $PWD
    while true
        test -f "$candidate/.envrc"; and return 0
        test "$candidate" = /; and return 1
        set candidate (path dirname "$candidate")
    end
end

function __direnv_export
    __direnv_needs_export; or return
    command direnv export fish | source
end

function __direnv_export_eval --on-event fish_prompt
    __direnv_export

    if test "$direnv_fish_mode" != disable_arrow
        function __direnv_cd_hook --on-variable PWD
            if test "$direnv_fish_mode" = eval_after_arrow
                set -g __direnv_export_again 0
            else
                __direnv_export
            end
        end
    end
end

function __direnv_export_eval_2 --on-event fish_preexec
    if set -q __direnv_export_again
        set -e __direnv_export_again
        __direnv_export
        echo
    end

    functions --erase __direnv_cd_hook
end
