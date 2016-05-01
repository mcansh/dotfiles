# ~/.personal-scripts.sh

function gh() {

  # get your repository's remote origin url
  remote=$(git config --local --get remote.origin.url)

  # removes '.git' from the end of the remote
  remote=${remote%.git}

  # exit if there is no repository in the PWD
  if [ "$remote" == "" ]
    then
     echo "Not a git repository or no remote.origin.url set"
     exit 1;
  fi

  # construct the Github url
  url=${remote/git\@github\.com\:/https://github.com/}

  # open the url
  open $url
}
