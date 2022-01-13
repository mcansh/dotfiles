function gitNotPushed
    set current_branch (git rev-parse --abbrev-ref HEAD)
    set count (git rev-list origin/$current_branch...$current_branch --count)
    if test $count -gt 0
        git log --pretty=format:"%C(yellow)%h\\ %ad%Cred%d\\ %Creset%s%Cblue\\ [%cn]" --decorate --date=relative origin/$current_branch..$current_branch
    else
        echo "origin/$current_branch is up to date with $current_branch"
    end
end
