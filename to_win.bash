# Set focus to matching window title.
# This is specific to my custom window titles.

# All the following logic to stay on the current 
# desktop while changing window focus using window 
# titles that are the same across desktops.
# A plain wmctrl -a "name" will jump between desktops.

# Window title to look for (can be partial)
winTitle=$1

# Which desktop is current. Look for asterisk
_desktop=$(wmctrl -d | grep "*" | awk '{ print $1 }')

# Find windows matching a partial window title,
# then test for matching desktop and return the window
_window=$(wmctrl -l | awk "/$winTitle/ { if (\$2 == $_desktop) \
                          { print \$1; exit} }")

# Switch to the window using the window ID
wmctrl -i -a $_window
