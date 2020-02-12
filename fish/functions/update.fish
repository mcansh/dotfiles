function update
  echo "▲ running macOS update"
  if test $argv = '--restart'
    echo '▲ using "--restart" requires root privileges, I don\'t make the rules'
    sudo softwareupdate -ia --verbose --restart
  else
    softwareupdate -ia --verbose
  end
end
