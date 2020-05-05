function clone_folder
    set folder (echo "$argv" | sed -e 's/.*\///g')
    set repo (string replace -r "/tree/master" "/trunk" $argv)
    echo $argv
    echo $folder
    echo $repo
    svn checkout $repo
end
