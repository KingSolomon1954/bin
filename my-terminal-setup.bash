#!/usr/bin/env bash

# This runs as one of the last steps in .bashrc. 
# The purpose is to setup and sync the correct history file
# with this particular terminal window. Based on the window's
# title, we figure out which history file to use.

# Grab current window id using xdpyinfo
str=$(xdpyinfo | grep focus)

# str now contains something like this:
#
#     focus:  window 0x3c0015e, revert to Parent
#
# When it says revert to parent, the window we're interested
# in is one less than the focused window, which is the parent.

# Grab the window id field
hexVal=$(echo $str | awk '{print $3}' )

# hexVal now contains something like: 
#     0x3c0015e,

# Remove trailing comma
hexVal=${hexVal%%,}

# Subtract 1 to obtain the parent windowId
printf -v windowId '%#x' "$(( hexVal - 1 ))"

# Need a leading 0 after the 0x and the hex number in order
# to match the output of wmctrl. So turn this 0x3c0015e into
# 0x03c0015e. If length of hex string is 9, then it needs a 0.
#
if [[ ${#windowId} -eq 9 ]]; then
    windowId=${windowId/0x/0x0}
fi

# echo "Window ID: $hexVal $windowId"

# Now we're able to look at the output of wmctrl -l and locate 
# the listing for the current window by id and obtain the title.
#
wmctrlListing=$(wmctrl -l | grep ${windowId})

# Grab the window title, starts at 4th field
title=$(echo $wmctrlListing | awk '{$1=$2=$3=""; print $0}')

# Remove any leading whitespace
title=${title#"${title%%[![:space:]]*}"}

# echo "Window Title:$title"

# Just want the number from the window title. This agrees
# with how the eight-terminals script named the windows.
# Eliminate all except the first word, which is a number
# 1 through 8.
#
num=${title%% *}

# echo "Window Number from Title:$num"

case $num in
    1|2|3|4|5|6|7|8)
        hist_file $num
        cdr
        cdg;;
esac

unset num
unset title
unset windowId
unset wmctrlListing
unset hexVal
unset str
