hist_sync $1

if [ $1 -eq 1 ]; then
    title "1 Upper Left"
elif [ $1 -eq 2 ]; then
    title "2 Lower Left"
elif [ $1 -eq 3 ]; then
    title "3 Upper Right"
elif [ $1 -eq 4 ]; then
    title "4 Lower Right"
else
    echo "Missing title for $1"
fi

cdr
cdg
