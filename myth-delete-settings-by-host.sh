#!/bin/sh

# Author: Piotr Oniszczuk warpme@o2.pl


version="1.0"
debug="0"
log_path="./"
log_filename="myth-delete-settings-by-host.log"

# list of tables with 'hostname' colon
tables_list="displayprofilegroups housekeeping jumppoints keybindings music_playlists settings weatherscreens"

# list of tables with 'host' colon
tables_list1="internetcontent"

















host_name=$1

Log() {
    echo >&2 "$*"
    echo >&2 "`date '+%H:%M:%S.%N'`: $*" >> ${log_path}${log_filename}
}

Debug() {
    if [ $debug = "1" ]; then
        echo "$*"
        echo >&2 "`date '+%H:%M:%S.%N'`: $*" >> ${log_path}${log_filename}
    fi
}

Die() { echo >&2 "$*"; exit 1; }

Log ""
Log "MythTV settings delete script v$version"

if [ -z "$host_name" ]; then
    Log ""
    Log "To delete setting for given hostname - call this script with hostname"
    Log ""
    action="list_hosts"
else
    action="delete_host"
    Log ""
    Log "Deleting settings for host: \"$host_name\""
    Log ""
fi

# Parameters to access DB
: ${MYTHCONFDIR:="$HOME/.mythtv"}
if [ -r "$MYTHCONFDIR/config.xml" ]; then
    export MYTHCONFDIR
    # mythbackend in Fedora packages has $HOME=/etc/mythtv
    elif [ -r "$HOME/config.xml" ]; then
        export MYTHCONFDIR="$HOME"
    elif [ -r "$HOME/.mythtv/config.xml" ]; then
        export MYTHCONFDIR="$HOME/.mythtv"
    elif [ -r "/home/mythtv/.mythtv/config.xml" ]; then
        export MYTHCONFDIR="/home/mythtv/.mythtv"
    elif [ -r "/etc/mythtv/config.xml" ]; then
        export MYTHCONFDIR="/etc/mythtv"
fi


# mythtv mysql database
if [ -r "$MYTHCONFDIR/config.xml" ]; then
    MYTHHOST=$(grep '<Host>'         <"$MYTHCONFDIR/config.xml" | sed -e 's/\s*<Host>\s*\(.*\)\s*<\/Host>\s*/\1/') #'
    MYTHUSER=$(grep '<UserName>'     <"$MYTHCONFDIR/config.xml" | sed -e 's/\s*<UserName>\s*\(.*\)\s*<\/UserName>\s*/\1/') #'
    MYTHPASS=$(grep '<Password>'     <"$MYTHCONFDIR/config.xml" | sed -e 's/\s*<Password>\s*\(.*\)\s*<\/Password>\s*/\1/') #'
    MYTHBASE=$(grep '<DatabaseName>' <"$MYTHCONFDIR/config.xml" | sed -e 's/\s*<DatabaseName>\s*\(.*\)\s*<\/DatabaseName>\s*/\1/') #'
    Log ""
    Log "Using database"
    Log "    -Host : $MYTHHOST"
    Log "    -User : $MYTHUSER"
    Log "    -Pass : $MYTHPASS"
    Log "    -Dbase: $MYTHBASE"
    Log ""
else
    Log "Can not find config.xml with DB settings!"
fi

Sql() {
    [ -n "$MYTHBASE" ] || return 0
    Debug "DB query: mysql ${MYTHHOST:+-h$MYTHHOST} -u$MYTHUSER -p$MYTHPASS -D"$MYTHBASE" \"$@\""
    mysql ${MYTHHOST:+-h$MYTHHOST} -u$MYTHUSER -p$MYTHPASS -D"$MYTHBASE" "$@"
}

if [ "x$action" = "xlist_hosts" ]; then

    Log ""
    Log "---- MythTV DB has settings for following hosts: ----"
    Log ""
    rc=$(Sql -Bse "SELECT DISTINCT hostname FROM settings;")
    Debug "DB query returns: ${rc}"
    for host in ${rc} ; do
        Log ${host}
    done
    Log ""
    Log "-----------------------------------------------------"
    exit 0
fi

if [ "x$action" = "xdelete_host" ]; then

    Log "---- Deleting settings for host:\"$host_name\" ----"
    Log ""

    Log "==> Removing video profiles data ...."
    Log ""
    Log "    Video profilegroupid for hostname [${host_name}] to be removed:"
    rm -f /tmp/profiles.txt
    rc=$(Sql -Bse "SELECT profilegroupid FROM displayprofilegroups WHERE hostname = '${host_name}' INTO OUTFILE '/tmp/profiles.txt';")
    Log ${rc}
    profiles_id_list=`cat /tmp/profiles.txt`
    rm -f /tmp/profiles.txt
    Log ${profiles_id_list}
    Log ""
    for profile_id in ${profiles_id_list} ; do
        Log "    Removing video profile_id:[${profile_id}]"
        rc=$(Sql -Bse "DELETE FROM displayprofiles WHERE profilegroupid = '${profile_id}';")
        Log ${rc}
    done

    Log "==> Removing settings & other related data ...."
    Log ""
    for table in ${tables_list} ; do
        Log "    Removing records with hostname [${host_name}] in table [${table}]"
        rc=$(Sql -Bse "DELETE FROM ${table} WHERE hostname = '${host_name}';")
        Log ${rc}
    done
    for table in ${tables_list1} ; do
        Log "    Removing records with host [${host_name}] in table [${table}]"
        rc=$(Sql -Bse "DELETE FROM ${table} WHERE host = '${host_name}';")
        Log ${rc}
    done

    Log ""
    Log "-----------------------------------------------------"
    Log ""
    Log "Done!..."
    Log ""
    exit 0
fi

exit 0
