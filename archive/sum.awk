awk "{sum += \$$colnum} END{print sum}" ${1+"$@"}
