function gitFixLastCommit {
  emojis=('🌮' '🦄' '🍕' '📜' '📦')
  length=${#emojis[@]}
  index=$((RANDOM % $length + 1))
  emoji=${emojis[$index]}
  gitDiffCount="$(git diff --cached --numstat | wc -l)"
  if (($gitDiffCount > 0))
  then
    echo "> 1/2 Getting last commit's sha"
    sha="$(git rev-parse HEAD)"
    echo '> 2/2 commiting staged files'
    git commit -s --fixup $sha
    echo "> Done. ${emoji}"
  else
    echo "> Stage some stuff and then try again"
  fi
}
