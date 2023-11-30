

hfiles="1-UpperLeft-d2 2-LowerLeft-d2 3-UpperRight-d2 4-LowerRight-d2 \
        1-UpperLeft-d3 2-LowerLeft-d3 3-UpperRight-d3 4-LowerRight-d3"

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
        ~/.history/$f.hist > ~/tmp/$f.hist
    mv ~/tmp/$f.hist ~/.history/$f.hist
done
