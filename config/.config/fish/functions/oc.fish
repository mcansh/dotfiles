function oc -d "runs opencode"
    if command --search opencode2 > /dev/null
        opencode2 "$argv"
    else
        opencode "$argv"
    end
end
