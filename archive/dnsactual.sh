#!/bin/bash

LOG_DIR=${HOME}/log
LAST_FILE=${LOG_DIR}/PublicIpAddrLast.txt
CHECK_FILE=${LOG_DIR}/PublicIpAddrCheck.txt
LOG_FILE=${LOG_DIR}/PublicIpAddr.log
HIST_FILE=${LOG_DIR}/PublicIpAddrHistory.log

if wget http://freedns.afraid.org/dynamic/check.php -o ${LOG_FILE} -O ${CHECK_FILE}; then
    CURRENT_IP=$(grep Detected ${CHECK_FILE} | cut -d : -f 2 | tr -d " ")
    if [ "${CURRENT_IP}" = "" ]; then
        echo "Error in script: no value for current ip"
        echo `date` "Error in script: no value for current ip" >> ${HIST_FILE}
        exit 0
    fi
else
    echo "Error from wget: see ${LOG_FILE}"
    echo `date` Error from wget >> ${HIST_FILE}
    exit 0
fi

# We obtained our current public IP address from dynamic dns site.

if [ -f ${LAST_FILE} ] ; then
    LAST_IP=$(cat ${LAST_FILE})
    #echo $LAST_IP
fi

if [ "${CURRENT_IP}" = "${LAST_IP}" ]; then
    # Our public IP address hasn't changed
    # No need to inform free.afraid.org
    echo "Public IP addr has not changed: ${CURRENT_IP}"
else
    # Our public IP address has changed
    echo "Public IP addr has changed. Telling http://free.afraid.org to use:" ${CURRENT_IP}
    echo "Public IP addr has changed. Telling http://free.afraid.org to use:" ${CURRENT_IP} >> ${HIST_FILE}
    wget http://freedns.afraid.org/dynamic/update.php?VVh2cUY2MzFVMVVBQU8tZldPa0FBQUFCOjk0MzE1NDU= -o ${LOG_FILE} -O /dev/stdout
    echo `date`  "Told http://freedns.afraid.org/ to use IP addr: " ${CURRENT_IP} >> ${HIST_FILE}
    echo ${CURRENT_IP} > ${LAST_FILE}
fi
