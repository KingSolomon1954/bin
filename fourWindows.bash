# Repostion and optionally restore size of my bash windows.
# This is only for MacOS.
# Use a script to send a URL notice to hammerspoon to
# perform the action. I prefer this over binding to a
# hotkey sequence.

# Any argument means use sizing.
if [ $# -gt 0 ]; then
    SIZING="?doSizing=true"
fi

open -g hammerspoon://fourTerminals${SIZING}
