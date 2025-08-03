function o -d "opens either the current directory or the one provided"
    if test "$argv"
        open "$argv"
    else
        open .
    end
end
