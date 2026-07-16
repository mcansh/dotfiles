function try --description 'Create and switch between temporary project worktrees'
    set -l out (/usr/bin/env ruby "$HOME/.local/try.rb" exec --path "$HOME/Developer/tries" $argv 2>/dev/tty | string collect)

    if test $status -eq 0
        eval $out
    else
        echo $out
    end
end
