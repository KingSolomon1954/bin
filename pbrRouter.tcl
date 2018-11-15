#!/usr/bin/expect
#
# File: pbrRouter.tcl
#
# Adds or deletes routes with a Cicsco Policy
# Based Router.
# 
# This script stays in operation the entire time
# RTNMS is running. It is exec'd once for each
# router during RTNMS initialization.
#
# At startup, the script logs-in to the Cisco
# PBR routers using ssh. Supports just one PBR.
# The script maintains a persistent SSH session
# with the PBR for the life of the program.
# If the SSH session gets disconnected for some 
# reason the script will attempt to reconnect
# every so many seconds.

# At startup the script also opens a persistent TCP
# socket connection back to RTNMS. The socket receives
# commands from RTNMS to add or delete routes. After
# processing each command a reply is sent back to RTNMS
# with the result of the operation.
#
# Requires four command line arguments:
#
#    arg0 = (required) TCP port to connect back to RTNMS 
#    arg1 = (required) Runtime directory 
#    arg2 = (required) IP address of PBR
#    arg4 = (required) identity 
#
# When SSH'ing into a PBR, a username/password is required.
# The script supplies a default username and
# password. But if the file "pbrRouterXXX.XXX.XXX.XXX.txt"
# is found in the local <runtime>/cfg directory, then
# username(s)/password(s) are taken from there.
#
# LIMITATIONS
#
# During SSH timeout detection, events back up and 
# can overflow the TCL interpreter vwait queue.
#
# Regarding the nasty condition I noticed late last night, I
# haven't been able to resolve that (yet). This condition is
# really a TCL internal "event queue overflow". It is
# related to the TCL internal event handling loop (vwait)
# together with Expect timeouts. I tried many things last
# night to no avail. This morninig I've been all over the
# web to see if I can figure something out. No luck. I
# intend on experimenting with the Tcl/Expect script to
# queue up router operations and see if I can somehow step
# these off and in so doing allow an Expect timeout
# in-progress (from a hung PBR SSH session) a chance to
# complete. But I'll have to come back to this at a later
# time
#
# ------------------------------------------------------

proc logOpen { } {
    set logFileName "$::rtnmsRootDir/log/pbrRouter$::pbrIpAddr.log"
    
    if {[catch {set ::logFd [open $logFileName w]} error]} {
        puts stderr "Unable to open $logFileName: $error"
        set ::logFd ""
    }
}

# ------------------------------------------------------

proc logError {msg} {
    set detail "Error: $msg"
    logMsg $detail
}

# ------------------------------------------------------

proc logMsg {msg} {
    set msg "[timestamp]: $msg"
    if {[catch {puts $::logFd $msg} writeError]} {
        puts stderr "Error writing to log file: $writeError"
        puts stderr $msg
    } else {
        flush $::logFd
    }
    
    incr ::currentLogSize [string length $msg]
    # if its greater than 100MB, close and reopen the log file
    if {$::currentLogSize > 100000000} {
        close $::logFd
        set ::currentLogSize 0
        logOpen
    } 
}

# ------------------------------------------------------

proc timestamp {} {
    set t [clock format [clock seconds] -format "%a %b %d %Y %X"]
    return $t
}

# ------------------------------------------------------

proc getVal {lines keyword} {
    set idx [lsearch $lines $keyword ]
    if {$idx < 0} {
        return
    }
    
    set info [split [lindex $lines $idx] "="]
    set val [lindex $info 1]
    set val [string trim $val]
    if {[string length $val] > 0} {
        return $val
    }
}

# ------------------------------------------------------
#
# If a file called "pbrRouterXXX.XXX.XXX.XXX.txt" exists,
# obtains PBR usr login and passwords from there. This is
# a mechanism for a site to override hardcoded defaults.
#
# Use this file to override user names and passwords for
# PBR ssh login account.
#
# File format: "keyword = value" pairs
#
# Keyword is case sensitive. Equal sign is required.
# Extra white space is trimmed. Not all entries need
# to appear in the file, just the one you want to override.
# Comments are ok. No special comment character.
# Just dont have keyword in comment.
#
#     Username = myUsername
#     Passwd   = myPassword
#
proc getPbrLoginInfoFromFile {} {
    set cfgFileName "$::rtnmsRootDir/cfg/pbrRouter$::pbrIpAddr.txt"
    
    if {[catch {set f [open $cfgFileName]} err]} {
        return
    }
    set contents [read $f]
    catch {close $f} err
    
    set lines [split $contents \n]
    
    set s [getVal $lines "Username*" ]
    if {[string length $s] > 0} {
         set ::pbrUsrname $s
    }
    
    set s [getVal $lines "Passwd*" ]
    if {[string length $s] > 0} {
         set ::pbrPasswd $s
    }
}

# ------------------------------------------------------

proc connectToPbr {} {
    logMsg "Connecting to PBR$::ident $::pbrIpAddr"
    if {[catch {loginToPbr} err]} {
        if {$::pbrSpawnId != 0} {
            catch {close -i $::pbrSpawnId}
            wait -i $::pbrSpawnId
            set ::pbrSpawnId 0
        }
        set err "[string trimright $err]. Will retry periodically."
        logError $err
        notifyRtnms $::notifyDisconnected $err
    } else {
        set connStr "PBR$::ident $::pbrIpAddr has connected via SSH."
        logMsg $connStr
        notifyRtnms $::notifyConnected $connStr
        set ::isPbrConnected true
    }
}

# ------------------------------------------------------

proc loginToPbr {} {
    
    spawn ssh $::pbrUsrname@$::pbrIpAddr
    set ::pbrSpawnId $spawn_id
    
    set cnt 0
    set s "PBR$::ident Spawning ssh $::pbrUsrname@$::pbrIpAddr:"
    
    expect {
        -timeout 2
        --
        "(yes/no)? " {
            send "yes\r"
            exp_continue
        }
        -nocase "password: " {
            send $::pbrPasswd\r
            exp_continue
        }
        "#" {
            # We're in.
            # Disable the --more-- division in output and
            # enable configuration mode
            send "term len 0\r"
            expect "#"
            send "configure terminal\r"
            expect "#"
        }
        -nocase "denied" {
            set eStr "$s PBR denied access due to bad user/password."
            error "$eStr $expect_out(buffer)"
        }
        timeout {
            if {$cnt < 3} {
                incr cnt
                exp_continue
            }
            set eStr "$s Timedout waiting for password prompt."
            error $eStr
        }
        eof {
            set eStr "$s got EOF from SSH."
            error "$eStr $expect_out(buffer)"
        }
    }
}

# ------------------------------------------------------

proc handleSigTerm {} {
    logMsg "Terminating due to SIGTERM signal."
    disconnectFromPbr
    exit 0
}
    
# ------------------------------------------------------

proc disconnectFromPbr {} {
    if {$::pbrSpawnId != 0} {
        set timeout 1
        send   -i $::pbrSpawnId "\r"
        expect -i $::pbrSpawnId "#"
        send   -i $::pbrSpawnId "exit\r"
        expect -i $::pbrSpawnId "#"
        send   -i $::pbrSpawnId "logout\r"
        expect -i $::pbrSpawnId "closed."
    }
}

# ------------------------------------------------------

proc clearBuf { } {
    expect -i $::pbrSpawnId "*"
}

# ------------------------------------------------------

proc keepAlive {} {
    if {[catch {keepAlivePrime} err]} {
        logError "Exception from keepAlivePrime: $err"
    }
}

# ------------------------------------------------------

proc keepAlivePrime {} {
    send -i $::pbrSpawnId \r
    
    set cnt 1
    
    expect {
        -i $::pbrSpawnId 
        -timeout 1
        --
        "#" {
            # Do nothing.
        }
        timeout {
            if {$cnt < 11} {
                logError "keepAlive: timeout ($cnt)"
                incr cnt
                exp_continue
            }
            # Declare interface down
            set eStr "keepAlive: No response after 10 secs."
            logError $eStr
            handleSshDisconnect $eStr
            return
        }
        eof {
            set eStr "keepAlive: EOF."
            logError $eStr
            handleSshDisconnect $eStr
            return
        }
    }
}

# ------------------------------------------------------

proc handleSshDisconnect {notifyStr} {
    append notifyStr " PBR$::ident $::pbrIpAddr SSH session disconnected. Will retry periodically."
    
    if {$::pbrSpawnId != 0} {
        catch {close -i $::pbrSpawnId}
        exec kill -SIGKILL [exp_pid -i $::pbrSpawnId]
        wait -i $::pbrSpawnId
        set ::pbrSpawnId 0
    }
    set ::isPbrConnected false
    notifyRtnms $::notifyDisconnected $notifyStr
}

# ------------------------------------------------------

proc connectToRtnms { } {
    set host "localhost"

    # This does the connect. Blocks untils we connect.
    if {[catch {set ::rtnmsSock [socket $host $::rtnmsPort]} err]} {
        logError "Can't connect via TCP/IP back to RTNMS: $err"
        exit 1
    }
    logMsg "Connected to RTNMS"
        
    # Set up socket options
    fconfigure $::rtnmsSock -buffering none -translation binary
}

# ------------------------------------------------------

proc readFromRtnms {} {
    if {[catch {readFromRtnmsPart2 $::rtnmsSock} err]} {
        close $::rtnmsSock
        logMsg "Terminating due to fault: $err"
        disconnectFromPbr
        exit 1
    }
}

# ------------------------------------------------------

proc readFromRtnmsPart2 {sock} {

    # 40 bytes of header (ACH + UniqueID + ident)
    # 4 bytes - SyncWord (unused)
    # 4 bytes - hdrLength (unused)
    # 4 bytes - hdrVersion (unused)
    # 4 bytes - componentType (unused)
    # 4 bytes - componentId (unused)
    # 4 bytes - msgId <<< This is our command ID
    # 4 bytes - msgVersion (unused)
    # 4 bytes - payloadLength
    # 4 bytes - uniqueId
    # 4 bytes - ident
    
    if {[catch {set hdr [read $sock 40]} err]} {
        error "Reading hdr from RTNMS socket: $err"
    }
    
    if {[eof $sock]} {
        error "Reading hdr from socket: $err"
    }
    
    if {[fblocked $sock]} {
        logMsg "Warning: Partial read on hdr from RTNMS"    
    }
    
    if {[catch {binary scan $hdr "IIIIIIIIII" syncW hdrLen hdrVer compType compId cmd msgVer payLen uniqueId ident} err]} {
        error "Bad hdr scan from RTNMS: $err"
    }
    
    # Our identity is given to us on the command line.
    # It distinguishes us from other PBR script instantiations.
    # It is also sent in every message. In msg we just ignore.
    
    # payload length as read from the header is the ACH length field
    # we subtract 8 bytes (uniqueId and ident) since we've already
    # read them but are counted in the ACH length field
    set payLen [expr $payLen - 8]
    
    set payload ""
    if {$payLen > 0} {
        if {[catch {set payload [read $sock $payLen]} err]} {
            error "Reading payload from RTNMS socket: $err"
        }
            
        if {[eof $sock]} {
            error "Reading payload from socket: $err"
        }
        
        if {[fblocked $sock]} {
            logMsg "Warning: Partial read on payload from RTNMS"    
        }
    }
    processCmd $cmd $uniqueId $payload
}

# ------------------------------------------------------

proc processCmd {cmd uniqueId payload} {
    set cmdResponse      1
    set cmdTerminate     2
    set cmdHeartBeat     3
    set cmdAddRoute      4
    set cmdDelRoute      5
    set cmdUpdateRoute   6
    set cmdNotify        7
    set cmdQueryRoutes   9
    
    switch -- $cmd \
        $cmdTerminate     {processTermCmd          $uniqueId $payload} \
        $cmdHeartBeat     {processHeartBeat        $uniqueId $payload} \
        $cmdAddRoute      {processAddRouteCmd      $uniqueId $payload} \
        $cmdDelRoute      {processDelRouteCmd      $uniqueId $payload} \
        $cmdUpdateRoute   {processUpdateRouteCmd   $uniqueId $payload} \
        $cmdQueryRoutes   {processQueryRoutesCmd   $uniqueId} \
        default {logMsg "Unrecognized cmd from RTNMS: $cmd"}
}

# ------------------------------------------------------

# This is obsolete code.  Keeping it around for just
# a bit. Used to terminate via a command from RTNMS.
# Now use the SIGTERM signal. Had trouble at first
# getting SIGTERM signal sent from a multi-threaded 
# program that forks a child process to the child.
#
proc processTermCmd {uniqueId payload} {
    logMsg "Rcvd Terminate Cmd"
#    disconnectFromPbr
#    set ::exiting true
}

# ------------------------------------------------------
#
# Heartbeats come from RTNMS every 30 seconds.
# We use it to keep the SSH session alive (prevent 
# SSH timeout). If we're not connected to SSH, then
# we use the heartbeat to trigger a reconnect every 
# so often, every other heartbeat, about 60 seconds.
#
proc processHeartBeat {uniqueId payload} {
    incr ::heartBeatCnt
    if {$::isPbrConnected} {
        keepAlive
    } else {
        if {[expr {$::heartBeatCnt % 2}] == 0} {
            connectToPbr
        }
    }
}

# ------------------------------------------------------

proc processAddRouteCmd {uniqueId payload} {
    logMsg "Rcvd Add Route Cmd"
    
    if {! $::isPbrConnected} {
        set rspStr "AddRoute: No connection to PBR$::ident $::pbrIpAddr."
        set rspCode $::rspCodeDisconnect
        reply $uniqueId $rspCode $rspStr
        logMsg "Add Route: no action, SSH not connected."
        return
    }
    
    # 4-byte numBlocks
    # 4-byte hostIpAddr
    # 4-byte hostIpMask
    # 4-byte gatewayIpAddr
    # Address block repeats. Total of 5 blocks
    
    array set dest []
    array set mask []
    array set gw   []
    
    binary scan $payload "IA16A16A16A16A16A16A16A16A16A16A16A16A16A16A16" \
                         numBlocks \
                         dest(0) mask(0) gw(0) \
                         dest(1) mask(1) gw(1) \
                         dest(2) mask(2) gw(2) \
                         dest(3) mask(3) gw(3) \
                         dest(4) mask(4) gw(4)
    
    for {set i 0} {$i < $numBlocks} {incr i} {
        set rtnList [addRoute $dest($i) $mask($i) $gw($i)]
        set rspCode [lindex $rtnList 0]
        set rspStr  [lindex $rtnList 1]
        if {$rspCode != $::rspCodeSuccess} {
            if {$rspCode == $::rspCodeTimeout} {
                # If we timedout, RTNMS itself has timedout 
                # long ago and is no longer expecting a reply.
                logError "Timedout in processAddRouteCmd"
                return
            }
            logError $rspStr
            break
        }
    }
     
    after 20   
    reply $uniqueId $rspCode $rspStr
}

# ------------------------------------------------------
proc processDelRouteCmd {uniqueId payload} {
    logMsg "Rcvd Del Route Cmd"
    
    if {! $::isPbrConnected} {
        set rspStr "DelRoute: No connection to PBR$::ident $::pbrIpAddr."
        set rspCode $::rspCodeDisconnect
        reply $uniqueId $rspCode $rspStr
        logMsg "Del Route: no action, SSH not connected."
        return
    }
    
    array set dest []
    array set mask []
    array set gw   []
    
    binary scan $payload "IA16A16A16A16A16A16A16A16A16A16A16A16A16A16A16" \
                         numBlocks \
                         dest(0) mask(0) gw(0) \
                         dest(1) mask(1) gw(1) \
                         dest(2) mask(2) gw(2) \
                         dest(3) mask(3) gw(3) \
                         dest(4) mask(4) gw(4)
     
    for {set i 0} {$i < $numBlocks} {incr i} {
        set rtnList [delRoute $dest($i) $mask($i) $gw($i)]
        set rspCode [lindex $rtnList 0]
        set rspStr  [lindex $rtnList 1]
        if {$rspCode != $::rspCodeSuccess} {
            if {$rspCode == $::rspCodeTimeout} {
                # If we timedout, RTNMS itself has timedout 
                # long ago and is no longer expecting a reply.
                logError "Timedout in processDelRouteCmd"
                return
            }
            logError $rspStr
            break
        }
    }
        
    reply $uniqueId $rspCode $rspStr
}

# ------------------------------------------------------

proc processUpdateRouteCmd {uniqueId payload} {
    logMsg "Rcvd Update Route Cmd"
    
    if {! $::isPbrConnected} {
        set rspStr "UpdateRoute: No connection to PBR$::ident $::pbrIpAddr."
        set rspCode $::rspCodeDisconnect
        reply $uniqueId $rspCode $rspStr
        logMsg "Update Route: no action, SSH not connected."
        return
    }
    
    # 4-byte numBlocks
    # 4-byte hostIpAddr
    # 4-byte hostIpMask
    # 4-byte gatewayIpAddr
    # Address block repeats. Total of 5 blocks
    
    array set dest []
    array set mask []
    array set gw   []
    
    binary scan $payload "IA16A16A16A16A16A16A16A16A16A16A16A16A16A16A16" \
                         numBlocks \
                         dest(0) mask(0) gw(0) \
                         dest(1) mask(1) gw(1) \
                         dest(2) mask(2) gw(2) \
                         dest(3) mask(3) gw(3) \
                         dest(4) mask(4) gw(4)
    
    for {set i 0} {$i < $numBlocks} {incr i} {
        delFuzzyRoute $dest($i) $mask($i) 
        set rtnList [addRoute $dest($i) $mask($i) $gw($i)]
        set rspCode [lindex $rtnList 0]
        set rspStr  [lindex $rtnList 1]
        if {$rspCode != $::rspCodeSuccess} {
            if {$rspCode == $::rspCodeTimeout} {
                # If we timedout, RTNMS itself has timedout 
                # long ago and is no longer expecting a reply.
                logError "Timedout in processUpdateRouteCmd"
                return
            }
            logError $rspStr
            break
        }
    }

    after 20        
    reply $uniqueId $rspCode $rspStr
}

# ------------------------------------------------------

proc processQueryRoutesCmd {uniqueId} {
    logMsg "Rcvd Query Routes Cmd"
    
    if {! $::isPbrConnected} {
        set rspStr "queryRoutes: No connection to PBR$::ident $::pbrIpAddr."
        set rspCode $::rspCodeDisconnect
        reply $uniqueId $rspCode $rspStr
        logMsg "Query Routes: no action, SSH not connected."
        return
    }
    
    set rtnList [queryRoutes $uniqueId]
    set rspCode [lindex $rtnList 0]
    set rspStr  [lindex $rtnList 1]
    if {$rspCode != $::rspCodeSuccess} {
        if {$rspCode == $::rspCodeTimeout} {
            # If we timedout, RTNMS itself has timedout 
            # long ago and is no longer expecting a reply.
            logError "Timedout in processQueryRoutesCmd"
            return
        }
        logError $rspStr
        break
    }

    # no additional reply. 
    #The report done w/ matching count is its own ack
}

# ------------------------------------------------------

proc addRoute {h m g} {
    clearBuf
    set expect_out(buffer) ""
    
    set s "ip route $h $m $g"
    logMsg $s
    
    send -i $::pbrSpawnId $s\r
    
    expect {
        -i $::pbrSpawnId 
        -timeout $::timeoutSecs
        --
        "^%*" {
            # Capture error string
            return [list $::rspCodeError "addRoute: $expect_out(buffer)"]
        }
        "#" {
            # Success
            return [list $::rspCodeSuccess ""]
        }
        timeout {
            set eStr "addRoute: No response after $::timeoutSecs secs."
            handleSshDisconnect $eStr
            return [list $::rspCodeTimeout $eStr]
        }
        eof {
            set eStr "addRoute: EOF."
            handleSshDisconnect $eStr
            return [list $::rspCodeDisconnect $eStr]
        }
    }    
    return [list $::rspCodeError "addRoute: unmatched expect buffer"]
}

# ------------------------------------------------------
#
# This delete performs an explicit delete, meaning that
# the gateway is considered when matching the route to
# delete. This is not currently used as the fuzzy delete
# seems to handle all the application needs
#
proc delRoute {h m g} {
    clearBuf
    set expect_out(buffer) ""
    
    set s "no ip route $h $m $g"
    logMsg $s
    
    send -i $::pbrSpawnId $s\r
    
    expect {
        -i $::pbrSpawnId 
        -timeout $::timeoutSecs
        --
        "%No matching route to delete" {
            # OK to delete non-existant route
            return [list $::rspCodeSuccess ""]
        }
        "%*" {
            # Capture error string
            return [list $::rspCodeError "delRoute: $expect_out(buffer)"]
        }
        "#" {
            # Success
            return [list $::rspCodeSuccess ""]
        }
        timeout {
            set eStr "delRoute: No response after $::timeoutSecs secs."
            handleSshDisconnect $eStr
            return [list $::rspCodeTimeout $eStr]
        }
        eof {
            set eStr "delRoute: EOF."
            handleSshDisconnect $eStr
            return [list $::rspCodeDisconnect $eStr]
        }
    }
    return [list $::rspCodeError "delRoute: unmatched expect buffer"]
}

# ------------------------------------------------------
#
# Deletes a host route without specifying a matching
# gateway. The router accepts this fuzzy delete route
# command and matches any gateway. Thus, this command will
# clear out any previous route for this host without having
# to know the exact previous route.
#
proc delFuzzyRoute {h m} {
    clearBuf
    set expect_out(buffer) ""
    
    set s "no ip route $h $m"
    logMsg $s
    
    send -i $::pbrSpawnId $s\r
    
    expect {
        -i $::pbrSpawnId 
        -timeout $::timeoutSecs
        --
        "#" {
            # Success or fail. Not interested in errors on this.
            return [list $::rspCodeSuccess ""]
        }
        timeout {
            set eStr "delFuzzyRoute: No response after $::timeoutSecs secs."
            handleSshDisconnect $eStr
            return [list $::rspCodeTimeout $eStr]
        }
        eof {
            set eStr "delFuzzyRoute: EOF"
            handleSshDisconnect $eStr
            return [list $::rspCodeDisconnect $eStr]
        }
    }
    return [list $::rspCodeError "delFuzzyRoute: unmatched expect buffer"]
}

# ------------------------------------------------------

proc reply {uniqueId posOrNeg errString} {
    
    # 40 bytes of header (ACH + UniqueID + ident):
    #     4 bytes - SyncWord (unused)
    #     4 bytes - hdrLength (unused)
    #     4 bytes - hdrVersion (unused)
    #     4 bytes - componentType (unused)
    #     4 bytes - componentId (unused)
    #     4 bytes - msgId <<< This is our response ID
    #     4 bytes - msgVersion (unused)
    #     4 bytes - payloadLength
    #     4 bytes - uniqueId
    #     4 bytes - ident
    
    # 260 bytes of payload:
    #     4 bytes - success or fail indicator
    #     256 bytes - error string
    
    set syncWord [expr 0x1acffc1d]
    set hdrLength 20
    set hdrVersion 0
    set componentType 10
    set componentId 0
    set cmdResponse 1
    set msgVersion 0
    set payLen [expr 8 + 260]
    set success 1
    if {$posOrNeg == false} {
        set success 2
    }
    
    set buf [binary format "IIIIIIIIIIIa256" \
     $syncWord \
     $hdrLength \
     $hdrVersion \
     $componentType \
     $componentId \
     $cmdResponse \
     $msgVersion \
     $payLen \
     $uniqueId \
     $::ident \
     $success \
     $errString \
    ]
    
    if {[catch {puts -nonewline $::rtnmsSock $buf} err]} {
        logError "Sending buf to RTNMS: $err"
    }
}
    
# ------------------------------------------------------

proc notifyRtnms {notifyCode notifyStr} {
    
    # 40 bytes of header (ACH + UniqueID + ident):
    #     4 bytes - SyncWord (unused)
    #     4 bytes - hdrLength (unused)
    #     4 bytes - hdrVersion (unused)
    #     4 bytes - componentType (unused)
    #     4 bytes - componentId (unused)
    #     4 bytes - msgId <<< This is our notify msg id
    #     4 bytes - msgVersion (unused)
    #     4 bytes - payloadLength
    #     4 bytes - uniqueId
    #     4 bytes - ident
    
    # 260 bytes of payload:
    #     4 bytes - notify code
    #     256 bytes - error string
    
    set syncWord [expr 0x1acffc1d]
    set hdrLength 20
    set hdrVersion 0
    set componentType 10
    set componentId 0
    set cmdNotify 7
    set msgVersion 0
    set payLen [expr 8 + 260]
    set uniqueId  0
    
    
    set buf [binary format "IIIIIIIIIIIa256" \
     $syncWord \
     $hdrLength \
     $hdrVersion \
     $componentType \
     $componentId \
     $cmdNotify \
     $msgVersion \
     $payLen \
     $uniqueId \
     $::ident \
     $notifyCode \
     $notifyStr \
    ]
    
    if {[catch {puts -nonewline $::rtnmsSock $buf} err]} {
        logError "Sending buf to RTNMS: $err"
    }
}

proc queryRoutes { uniqueId } {
    clearBuf
    set expect_out(buffer) ""
    
    set s "do show ip route static"
    logMsg $s

    send -i $::pbrSpawnId $s\r
    
    reportRouteBegin $uniqueId
    
    set count 0
    
    expect {
        -i $::pbrSpawnId 
        -timeout $::timeoutSecs
        --
        "^%*" {
            # Capture error string
            return [list $::rspCodeError "addRoute: $expect_out(buffer)"]
        }
        -re "S\\s+(\\d+\.\\d+\.\\d+\.\\d+)/(\\d+)..\\d+\.\\d+..via.(\\d+\.\\d+\.\\d+\.\\d+)" {
            reportRoute $uniqueId $expect_out(1,string) $expect_out(2,string) $expect_out(3,string)
            incr count
            exp_continue
        }
        "#" {
            # Success/Done
            reportRouteDone $uniqueId $count
            return [list $::rspCodeSuccess ""]
        }
        timeout {
            set eStr "queryRoutes: No response after $::timeoutSecs secs."
            handleSshDisconnect $eStr
            return [list $::rspCodeTimeout $eStr]
        }
        eof {
            set eStr "queryRoutes: EOF."
            handleSshDisconnect $eStr
            return [list $::rspCodeDisconnect $eStr]
        }
    }    
    return [list $::rspCodeError "queryRoutes: unmatched expect buffer"]
}

# ------------------------------------------------------

proc reportRouteBegin { uniqueId } {
    # 40 bytes of header (ACH + UniqueID + ident):
    #     4 bytes - SyncWord (unused)
    #     4 bytes - hdrLength (unused)
    #     4 bytes - hdrVersion (unused)
    #     4 bytes - componentType (unused)
    #     4 bytes - componentId (unused)
    #     4 bytes - msgId <<< This is our report msg id
    #     4 bytes - msgVersion (unused)
    #     4 bytes - payloadLength
    #     4 bytes - uniqueId
    #     4 bytes - ident
    #     4 bytes - report code 1 (report begin)
    #     4 bytes - count (unused / 0)
    #     4 bytes - addr (unused / 0)
    #     4 bytes - mask (unused / 0)
    #     4 bytes - gateway (unused / 0)
    
    set syncWord [expr 0x1acffc1d]
    set hdrLength 20
    set hdrVersion 0
    set componentType 10
    set componentId 0
    set msgReportBegin 10
    set msgVersion 0
    
    set payLen [expr 8 + 20]
    
    set reportCode 1
    set count 0
    set addr 0
    set mask 0
    set gateway 0
    
    set buf [binary format "IIIIIIIIIIIIIII" \
     $syncWord \
     $hdrLength \
     $hdrVersion \
     $componentType \
     $componentId \
     $msgReportBegin \
     $msgVersion \
     $payLen \
     $uniqueId \
     $::ident \
     $reportCode \
     $count \
     $addr \
     $mask \
     $gateway \
    ]
    
    if {[catch {puts -nonewline $::rtnmsSock $buf} err]} {
        logError "Sending buf to RTNMS: $err"
    }
    
}

# ------------------------------------------------------

proc reportRoute { uniqueId netAddr maskSpec gwAddr } {
    # 40 bytes of header (ACH + UniqueID + ident):
    #     4 bytes - SyncWord (unused)
    #     4 bytes - hdrLength (unused)
    #     4 bytes - hdrVersion (unused)
    #     4 bytes - componentType (unused)
    #     4 bytes - componentId (unused)
    #     4 bytes - msgId <<< This is our report msg id
    #     4 bytes - msgVersion (unused)
    #     4 bytes - payloadLength
    #     4 bytes - uniqueId
    #     4 bytes - ident
    #     4 bytes - report code 2 (report route)
    #     4 bytes - count (unused / 0)
    #     4 bytes - addr 
    #     4 bytes - mask
    #     4 bytes - gateway
    logMsg "reportRoute $uniqueId $netAddr $maskSpec $gwAddr"
    
    
    set syncWord [expr 0x1acffc1d]
    set hdrLength 20
    set hdrVersion 0
    set componentType 10
    set componentId 0
    set msgReportBegin 10
    set msgVersion 0
    
    set payLen [expr 8 + 20]

    set reportCode 2
    set count 0
    scan $netAddr "%d.%d.%d.%d" n1 n2 n3 n4
    set addr [expr ($n1<<24) + ($n2<<16) + ($n3<<8) + ($n4)]
    set mask $maskSpec
    scan $gwAddr "%d.%d.%d.%d" n1 n2 n3 n4
    set gateway [expr ($n1<<24) + ($n2<<16) + ($n3<<8) + ($n4)]
    
    set buf [binary format "IIIIIIIIIIIIIII" \
     $syncWord \
     $hdrLength \
     $hdrVersion \
     $componentType \
     $componentId \
     $msgReportBegin \
     $msgVersion \
     $payLen \
     $uniqueId \
     $::ident \
     $reportCode \
     $count \
     $addr \
     $mask \
     $gateway \
    ]

    
    if {[catch {puts -nonewline $::rtnmsSock $buf} err]} {
        logError "Sending buf to RTNMS: $err"
    }
    
}

# ------------------------------------------------------

proc reportRouteDone { uniqueId count } {
    # 40 bytes of header (ACH + UniqueID + ident):
    #     4 bytes - SyncWord (unused)
    #     4 bytes - hdrLength (unused)
    #     4 bytes - hdrVersion (unused)
    #     4 bytes - componentType (unused)
    #     4 bytes - componentId (unused)
    #     4 bytes - msgId <<< This is our report msg id
    #     4 bytes - msgVersion (unused)
    #     4 bytes - payloadLength
    #     4 bytes - uniqueId
    #     4 bytes - ident
    #     4 bytes - report code 3 (report done)
    #     4 bytes - count (number of routes sent)
    #     4 bytes - addr (unused / 0)
    #     4 bytes - mask (unused / 0)
    #     4 bytes - gateway (unused / 0)
    
    set syncWord [expr 0x1acffc1d]
    set hdrLength 20
    set hdrVersion 0
    set componentType 10
    set componentId 0
    set msgReportBegin 10
    set msgVersion 0
    
    set payLen [expr 8 + 20]
    
    set reportCode 3
    set addr 0
    set mask 0
    set gateway 0
    
    set buf [binary format "IIIIIIIIIIIIIII" \
     $syncWord \
     $hdrLength \
     $hdrVersion \
     $componentType \
     $componentId \
     $msgReportBegin \
     $msgVersion \
     $payLen \
     $uniqueId \
     $::ident \
     $reportCode \
     $count \
     $addr \
     $mask \
     $gateway \
    ]
    
    if {[catch {puts -nonewline $::rtnmsSock $buf} err]} {
        logError "Sending buf to RTNMS: $err"
    }
    
}
    
# ------------------------------------------------------

# exp_internal 1
set timeoutSecs   15

# These are used in the response message to
# a router operation.

set rspCodeSuccess     1
set rspCodeError       2
set rspCodeTimeout     3
set rspCodeDisconnect  4
        
# These are used in the unsolicited notify message.

set notifyInfo         1
set notifyWarn         2
set notifyError        3
set notifyConnected    4
set notifyDisconnected 5

set pbrUsrname     "admin"
set pbrPasswd      "Coolsys1"
set isPbrConnected false
set pbrSpawnId     0
set heartBeatCnt   0

set rtnmsPort    [lindex $argv 0]
set rtnmsRootDir [lindex $argv 1]
set pbrIpAddr    [lindex $argv 2]
set ident        [lindex $argv 3]
set currentLogSize 0

logOpen
logMsg "Program started."

if {$argc < 3} {
    logError "Missing command line args"
    exit 1
}

trap {handleSigTerm} {SIGTERM SIGINT}
connectToRtnms
getPbrLoginInfoFromFile

connectToPbr

while {1} {
    readFromRtnms
}

# Script terminates on a SIGTERM signal - see handleSigTerm,
# or if a comm error is detected on the socket to RTNMS.
# Either way, we should get here.
