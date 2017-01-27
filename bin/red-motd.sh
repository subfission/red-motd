#!/bin/bash -
#title         :red-motd.sh
#description   :Redhat Simple MOTD Profile Script
#author        :Zach Jetson
#date          :20170120
#version       :1.1.1
#license       :GNU General Public License
# -----------------------------------------------------
## Installation
## Place this in /usr/local/bin, chmod +x the script, and call it from 
## the .bash_profile script. 
scriptName="$0"
ARGS="$@"
scriptFile=`which $0`


Update () {
  if [ "$EUID" -ne 0 ]; then 
    echo "Update check requires root privileges"
    echo "Example:"
    echo "    sudo $scriptFile $1"
    exit 1
  fi  
  echo "Updating MOTD script..."
  curl -s https://raw.githubusercontent.com/subfission/red-motd/master/bin/red-motd.sh > /usr/local/bin/red-motd
  echo "Complete!"
  echo
  echo
  $SCRIPT_FILE
  return 0
}

Collect () {
  hostname=`uname -n`
  rootStorage=`df -Ph | grep "/$" | awk '{print "Free: "$4", Used: "$3", Total: "$2}'`
  tmpStorage=`df -Ph | egrep "/tmp$" | awk '{print "Free: "$4", Used: "$3", Total: "$2}'`
  userCount=`users | wc -w`
  sessionCount=`who | grep -c "$USER"`

  MEMORY=`free -gho | grep "^Mem" | awk '{print "Free: "$4", Used: "$3", Total: "$2;}'`
  SWAP=`free -gho | grep "^Swap" | awk '{print "Free: "$4", Used: "$3", Total: "$2;}'`
  PSA=`ps -Afl | wc -l`
  MAXPROC=`/sbin/sysctl -n kernel.pid_max 2>/dev/null`
  IP="$(/sbin/ip route get 8.8.8.8 | head -1 | cut -d' ' -f8)"
  DATE=`date`
  apachePath=`which httpd 2>/dev/null`
  apacheVersion=`httpd -v | head -1 | awk '{print $3;}'`
  MySQLPath=`which mysql 2>/dev/null`
  MySQLVersion=`$MySQLPath --version 2>/dev/null | awk '{print $3" "$4" "$5;}' | tr -d ","`
  if [ -r /usr/local/cpanel/version ] ; then
    cpanelVersion=`cat /usr/local/cpanel/version | awk '{print "v"$1}'`
  else
    cpanelVersion="not installed"
  fi
  #System uptime
  uptime=`cat /proc/uptime | cut -f1 -d.`
  upDays=$((uptime/60/60/24))
  upHours=$((uptime/60/60%24))
  upMins=$((uptime/60%60))
  upSecs=$((uptime%60))

  #System load
  LOAD1=`cat /proc/loadavg | awk {'print $1'}`
  LOAD5=`cat /proc/loadavg | awk {'print $2'}`
  LOAD15=`cat /proc/loadavg | awk {'print $3'}`
}

Display () {
  echo -e " 
                  $USER @ $hostname
=================================================================
             IP = ${IP}
        Release = $(cat /etc/redhat-release)
         cPanel = $cpanelVersion
         Kernel = $(uname -rs)
         Apache = $apacheVersion at $apachePath
          MySQL = $MySQLVersion at $MySQLPath
          Users = Currently $userCount user(s) logged on
       Sessions = $sessionCount sessions
      CPU Usage = $LOAD1, $LOAD5, ${LOAD15} (1, 5, 15 min)
         Memory = $MEMORY
           Swap = $SWAP
        Storage = $rootStorage
   Temp Storage = $tmpStorage
      Processes = $PSA running of $MAXPROC maximum processes
  System Uptime = $upDays day(s) $upHours hours $upMins minutes $upSecs seconds
==================================================================
                  $DATE"
  echo
  
  return 0
}

PrintVersion () {
  version=`grep "^#version" $1 | awk '{print $2}' | tr -d ":"`
  echo "RedHat MOTD - Version: $version"
  return 0
}

while :; do
    case "$1" in
        -V|--version|--Version)
            PrintVersion ; exit 0 ;;
        -u|--update)
            Update ; exit 0 ;;
        -*) echo "You specified a non-existant option: $1" ; exit 2 ;;
        *) break ;;
    esac
done
Collect
Display
exit $?
