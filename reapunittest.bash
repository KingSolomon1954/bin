
# send SIGTERM to stale unit test processes

cntr=docker
if type -t podman 1>&2 > /dev/null; then
    cntr=podman
fi
${cntr} exec sgn-gcc9 ps aux | grep ut-sgn-lib-exec | awk '{ print $2 }' > ~/tmp/pids
if [ -s ~/tmp/pids ]; then
    ${cntr} exec sgn-gcc9 kill -s SIGTERM $(cat ~/tmp/pids)
fi
rm -f ~/tmp/pids
