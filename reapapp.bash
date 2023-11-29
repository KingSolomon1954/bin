
# send SIGKILL to $1 

cntr=docker
if type -t podman 1>&2 > /dev/null; then
    cntr=podman
fi
${cntr} exec sgn-gcc10-tools ps aux | grep "$1" | awk '{ print $2 }' > ~/tmp/pids
if [ -s ~/tmp/pids ]; then
    ${cntr} exec sgn-gcc10-tools kill -s SIGKILL $(cat ~/tmp/pids)
fi
rm -f ~/tmp/pids
