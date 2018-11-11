#!/bin/bash
#
# FILE
#     devutils.bash - development utility functions.
#
# SYNOPSIS
#     . devutils.bash 
#
# OPTIONS
#     None.
#
# DESCRIPTION
#     This file contains common utility functions used by most of the other
#     development environment scripts. It is not executable on its own, and
#     is meant to be sourced by other scripts. It is for "bash" scripts only.
#
# EXAMPLE
#     . devutils.bash
# 
# ENVIRONMENT
#     None.
#
# BUGS
#     No known bugs.
#
# -----------------------------------------------------------

baseName ()
{
    echo ${1##*/}
}

# -----------------------------------------------------------

dirName ()
{
    # Remove any trailing '/' that doesn't have anything following it (to
    # parallel the behavior of "dirname").
    #
    local tmp1=${1%/}

    # remove last level in path
    local tmp2=${tmp1%/*}

    # If there was nothing left after removing the last level in the path,
    # the path must be to something in the root directory, so the result
    # should just be the root directory. Otherwise, if there wasn't any last
    # level, the path must be to something in the current dir, so the result
    # should just be the current dir. Otherwise,
    #
    if [ "${tmp2}" = "" ]; then
        tmp2=/
    elif [ "${tmp2}" = "${tmp1}" ]; then
        tmp2=.
    fi

    echo ${tmp2}
}

# -------------------------------------------------------
#
# Output usage.
#
usage()
{
    # output prolog (up to first line that doesn't begin with #)
    /usr/bin/sed "/^[^#]*$/q" $0
}

# -------------------------------------------------------
#
# Output text to standard out.
#
stdOut()
{
    echo "$*"
}

# -------------------------------------------------------
#
# Output text to standard error.
#
stdErr()
{
    echo "$*" 1>&2
}
