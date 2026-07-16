# Vite+ environment setup without generating its completions during startup.
fish_add_path --path --move "$HOME/.vite-plus/bin"

# Preserve `vp env use`, which must evaluate Vite+'s output in this shell.
function vp
    if test (count $argv) -ge 2; and test "$argv[1]" = env; and test "$argv[2]" = use
        if contains -- -h $argv; or contains -- --help $argv
            command vp $argv
            return
        end

        set -lx VP_ENV_USE_EVAL_ENABLE 1
        set -l vp_output (env FISH_VERSION=$FISH_VERSION "$HOME/.vite-plus/bin/vp" $argv); or return $status
        eval (string join ';' $vp_output)
    else
        command vp $argv
    end
end
