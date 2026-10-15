function oc -d "runs opencode"
    if command --search opencode2 > /dev/null
        if test "$argv"
            opencode2 "$argv"
        else
            opencode2
        end
    else
        if test "$argv"
            opencode "$argv"
        else
            opencode
        end
    end
end
