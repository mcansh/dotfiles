function remixupgrade -d "updates remix to the provided npm tag"
    if test -z "$argv"
        echo "Usage: remixupgrade <tag>"
        echo "  remixupgrade @latest"
        echo "  remixupgrade @nightly"
        echo "  remixupgrade @pre"
        return 1
    end
    if test -e "package.json"
        ncu --target $argv --filter "@remix-run/*,remix" --reject "@remix-run/router" --upgrade --interactive --removeRange
    else
        echo "No package.json found in the current directory"
        return 1
    end
end


