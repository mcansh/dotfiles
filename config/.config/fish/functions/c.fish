function c -d "opens either the current directory or the one provided"
    # use code-insiders if available
    # fallback to code
    set cmd (command -v code-insiders || command -v code)

    if test -z "$cmd"
        echo "Visual Studio Code is not installed"
        return 1
    end

    if test -z "$argv"
        set directory (pwd)
    else
        set directory $argv
    end

    $cmd $directory
end
