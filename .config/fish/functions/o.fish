# Opens either the current directory or the one provided
function o
  if test "$argv"
    open "$argv"
  else
    open .
  end
end
