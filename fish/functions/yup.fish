function yup -d "update deps with yarn or npm"
    if test -e "yarn.lock"
        echo "yarn.lock file exists"
        yarnup
    else
        echo "no yarn.lock"
        ncu -u
    end
end
