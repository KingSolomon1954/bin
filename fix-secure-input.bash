
# Run this command. Shows the PID that is holding SecureInput 

ioreg -l -w 0 | grep SecureInput

echo "Find the PID with"
echo "ps aux"
echo "Then kill it, make sure it's not the root login window"
echo "kill -SIGTERM PID"
