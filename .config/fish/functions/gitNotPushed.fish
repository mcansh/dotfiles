function gitNotPushed
  current_branch="(git rev-parse --abbrev-ref HEAD)"
  count="(git rev-list origin/(current_branch)...(current_branch) --count)"
  if (($count > 0))
  then
    git log origin/(current_branch)..(current_branch)
  else
    echo "origin/$current_branch is up to date with $current_branch"
  fi
end
