function c -d "opens either the current directory or the one provided"
    if test "$argv"
        zed "$argv"
    else
        zed .
    end
end
