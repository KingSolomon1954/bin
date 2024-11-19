#!/usr/bin/env bash

# Grab current window id using xdpyinfo
str=$(xdpyinfo | grep focus)

# str now contains something like this:
#
#     focus:  window 0x3c0015e, revert to Parent
#
# When it says revert to parent, the window we're interested in,
# is one off from this window.

# Grab the window id field
hexVal=$(echo $str | awk '{print $3}' )

# hexVal now contains something like: 
#     0x3c0015e,

# Remove trailing comma
hexVal=${hexVal%%,}

# Subtract 1 to obtain the parent windowId
printf -v windowId '%#x' "$(( hexVal - 1 ))"

# Need a leading 0 between the 'x' and the '3' in order to
# match the output of wmctrl.
if [[ ${#windowId} -eq 9 ]]; then
    windowId=${windowId/0x/0x0}
fi

# echo "Window ID: $hexVal $windowId"

# Now we're able to look at output of wmctrl -l and locate 
# the current window by id, which has the title.
#
wmctrlListing=$(wmctrl -l | grep ${windowId})

# Grab the window title, starts at 4th field
title=$(echo $wmctrlListing | awk '{$1=$2=$3=""; print $0}')

# Remove any leading whitespace
title=${title#"${title%%[![:space:]]*}"}

# echo "Window Title:$title"

# Just want the number from the title
# Eliminate all except the first word
num=${title%% *}

# echo "Window Number from Title:$num"

case $num in
    1|2|3|4|5|6|7|8)
        hist_sync $num
        cdr
        cdg;;
esac

unset num
unset title
unset windowId
unset wmctrlListing
unset hexVal
unset str
