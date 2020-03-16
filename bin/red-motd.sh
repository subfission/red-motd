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
    exec sudo /bin/bash "$0" update
    exit 1
  fi  
  echo "Updating MOTD script..."
  CODE=$(curl -s "https://raw.githubusercontent.com/subfission/red-motd/master/bin/red-motd.sh" 2>/dev/null)
  [ -z "$CODE" ] && { echo "[!] Unable to download update" && exit 1; }
  
  echo "$CODE" > /usr/local/bin/red-motd
  echo
  echo "[+] $SCRIPT_FILE updated"
}

Collect () {
  # Get system type
  SYSTYPE=$(uname -o 2>/dev/null) 
  
  # System specific commands: FreeBSD, Debian/Ubuntu, CentOS/RedHat
  # ====== FreeBSD =======
  if [ $SYSTYPE == "FreeBSD" ]; then
    # May show multiple IPs which is fine
    IP=$(ifconfig 2>/dev/null | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p' | tr '\n' ' ')    
    MEMORY=$(top |grep -Em2 '^(Mem):'| sed -r 's/.{5}//')
    SWAP=$(top | grep -Em2 '^(Swap):'| sed -r 's/.{6}//')
  # ======= Ubuntu =======
  elif [[ $(lsb_release -i 2>/dev/null | cut -d: -f2 | tr -d '[:space:]') == "Ubuntu" ]]; then
     IP="$(/sbin/ip route get 8.8.8.8 | head -1 | cut -d' ' -f7)"
     RELEASE=$(lsb_release -d | cut -f2)
     APACHE=$(apachectl -v 2>/dev/null | head -1 | awk '{print $3 " " $4;}')
     MEMORY=`free -gh | grep "^Mem" | awk '{print "Free: "$4", Used: "$3", Total: "$2;}'`
     SWAP=$(free -gh | grep "^Swap" | awk '{print "Free: "$4", Used: "$3", Total: "$2;}')
  # ======= RedHat ======= 
  else
     IP="$(/sbin/ip route get 8.8.8.8 | head -1 | cut -d' ' -f7)"
     RELEASE=$(cat /etc/redhat-release)
     APACHE=$(apachectl -v 2>/dev/null | head -1 | awk '{ print $3 " " $4; }')
     MEMORY=`free -gh | grep "^Mem" | awk '{print "Free: "$4", Used: "$3", Total: "$2;}'`
     SWAP=`free -gh | grep "^Swap" | awk '{print "Free: "$4", Used: "$3", Total: "$2;}'`
  fi
  # ====== Defaults ======
  if [[ -z $APACHE ]]; then
    APACHE="not installed"
  fi
  # = Universal commands =
  hostname=`uname -n`
  rootStorage=`df -Ph / | grep -v Filesystem | awk '{print "Free: "$4", Used: "$3", Total: "$2}'`
  tmpStorage=`du -sh /tmp | cut -f1`
  userCount=`users | wc -w`
  sessionCount=`who | grep -c "$USER"`
  PSA=`ps -Afl | wc -l`
  MAXPROC=`/sbin/sysctl -n kernel.pid_max 2>/dev/null`
  DATE=`date`
  
  MySQLPath=`which mysql 2>/dev/null`
  if [ -z $MySQLPath ]; then
    MYSQL="not installed"
  else
    MYSQL=`$MySQLPath --version 2>/dev/null | awk '{print $3" "$4" "$5;}' | tr -d ","`
  fi
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
        Release = $RELEASE
         cPanel = $cpanelVersion
         Kernel = $(uname -rs)
         Apache = $APACHE
          MySQL = $MYSQL
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
  version=`grep "^#version" $scriptFile | awk '{print $2}' | tr -d ":"`
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
