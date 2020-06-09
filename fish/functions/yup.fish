function yup -d "update deps with yarn or npm"
    if test -e "yarn.lock"
        echo "yarn.lock file exists"
        yarnup
    else
        tput setaf 1
        echo "No yarn.lock"
        tput setaf 0
        ncu -u
    end
end
