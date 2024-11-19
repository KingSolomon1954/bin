

hfiles="1-left-col  2-left-col  3-left-col  4-left-col \
        5-right-col 6-right-col 7-right-col 8-right-col"

for f in ${hfiles}; do
    sed -e "/^l .*$/d" \
        -e "/^L .*$/d" \
        -e "/^rm .*$/d" \
        -e "/^cd .*$/d" \
        -e "/^$/d" \
        -e "/^...$/d" \
        -e "/^date$/d" \
        -e "/^clear$/d" \
        -e "/^make$/d" \
        -e "/^git push$/d" \
        -e "/^git pull$/d" \
        ~/.history/$f.hist > ~/tmp/$f.hist
    mv ~/tmp/$f.hist ~/.history/$f.hist
done
