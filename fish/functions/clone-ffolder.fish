function clone_folder
    set folder (echo "$argv" | sed -e 's/.*\///g')
    set repo (string replace -r "/tree/master" "/trunk" $argv)
    svn checkout $repo
end
