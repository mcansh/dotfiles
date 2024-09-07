function dl-audio -d "download the best audio from a youtube video, soundcloud, twitter, etc."
  if test -z "$argv"
    echo "Usage: dl-audio <url>"
    return 1
  end

  # youtube-dl --embed-thumbnail -f bestaudio --extract-audio --audio-format m4a --audio-quality 0 "https://www.youtube.com/watch?v=EXrbbdjgAA8"

  # youtube-dl -f "bestaudio/best" -ciw -o "%(title)s.%(ext)s" -v --extract-audio --audio-quality 0 --audio-format m4a  https://www.youtube.com/watch?v=c29tZVZpZGVvUGxheWxpc3RQYXJ0
end
