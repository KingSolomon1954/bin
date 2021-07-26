
# send SIGTERM to mtrTest

cntr=docker
if type -t podman 1>&2 > /dev/null; then
    cntr=podman
fi
${cntr} exec mtt-gcc7 ps aux | grep "mtrTest" | awk '{ print $2 }' > ~/tmp/pids
if [ -s ~/tmp/pids ]; then
    ${cntr} exec mtt-gcc7 kill -s SIGTERM $(cat ~/tmp/pids)
fi
rm -f ~/tmp/pids
