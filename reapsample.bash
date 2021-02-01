
# send SIGTERM to stale SampleApps

cntr=docker
if type -t podman 1>&2 > /dev/null; then
    cntr=podman
fi
docker exec sgn-gcc9 ps aux | grep SampleApp | colrm 16 | colrm 1 10 > ~/tmp/pids
if [ -s ~/tmp/pids ]; then
    docker exec sgn-gcc9 kill -s SIGTERM $(cat ~/tmp/pids)
fi
rm -f ~/tmp/pids
