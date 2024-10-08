function update
    echo "▲ running macOS update"
    if test (count $argv) -eq 1 -a "$argv[1]" = "--restart"
        echo '▲ using "--restart" requires root privileges, I don\'t make the rules'
        sudo softwareupdate --install --all --verbose --restart
    else
        softwareupdate --install --all --verbose
    end
end
