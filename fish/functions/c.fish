function c -d "opens either the current directory or the one provided"
    if test "$argv"
        code-insiders "$argv"
    else
        code-insiders .
    end
end
