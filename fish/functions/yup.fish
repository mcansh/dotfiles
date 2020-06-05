function yup -d "update deps with yarn or npm"
    if test -e "yarn.lock"
        echo "yarn.lock file exists"
        yarnup
    else
        tput setaf 1
        echo "No yarn.lock"
        ncu -u
    end
end
