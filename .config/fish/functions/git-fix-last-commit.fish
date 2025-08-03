function git-fix-last-commit
  set -l emoji (random choice '🌮' '🦄' '🍕' '📜' '📦')
  set -l gitDiffCount (git diff --staged --shortstat | awk '{print $1}')
  if test $gitDiffCount -gt 0
    echo "> 1/2 Getting last commit's sha"
    set -l sha (git rev-parse HEAD)
    echo '> 2/2 commiting staged files'
    git commit -s --fixup $sha
    echo "> Done. $emoji"
  else
    echo "> Stage some stuff and then try again"
  end
end
