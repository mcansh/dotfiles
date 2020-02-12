function docker_cleanup
  set -l containers (docker ps -aq)
  set -l images (docker images -q)
  if test $containers
    docker stop $containers
    docker rm $containers
  end

  if test $images
    docker rmi $images
  end
end
