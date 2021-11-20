
# send SIGTERM to stale Skeleton

cntr=docker
if type -t podman 1>&2 > /dev/null; then
    cntr=podman
fi
${cntr} exec sgn-gcc10-tools ps aux | grep Skeleton | awk '{ print $2 }' > ~/tmp/pids
if [ -s ~/tmp/pids ]; then
    ${cntr} exec sgn-gcc10-tools kill -s SIGTERM $(cat ~/tmp/pids)
fi
rm -f ~/tmp/pids
