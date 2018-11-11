#!/usr/bin/expect
#
# Try to keep the network connection alive
# so we can have overnight runs.
#
# ------------------------------------------------------

spawn ssh -X hsolomon@arc-dev09 -o ServerAliveInterval=300
    
# Send a harmless command every 60 seconds if we haven't
# typed anything.

interact {
    timeout 60 {
        send "date\r"
    }
}
