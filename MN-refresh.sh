#!/bin/bash

# Make sure curl is installed
clear
echo "Preparing background tools..."
apt-get -qq update
clear
echo "Preparing background tools... ... "
apt -qqy install curl jq > /dev/null 2>&1
clear

# Make sure dig and systemctl are installed
echo "Preparing background tools... ... ..."
apt-get install git dnsutils systemd -y > /dev/null 2>&1
clear

# Make sure dig and systemctl are installed
echo "Preparing background tools... ... ... ..."
# CHARS is used for the loading animation further down.
CHARS="/-\|"
clear

MNID=""
#GUAPDIR=""

echo "
___T_
| o o |
|__-__|
/| []|\\
()/|___|\()
|_|_|
/_|_\  ----------- MASTERNODE REFRESH v1 ----------------+
|                                                        |
|    This script will refresh the MN of your choice.     |
|                                                        |
| You must specify the ID# of the MN you wish to refresh |
|   E.g. If you want to refresh your initial MN, which   |
|        would have an ID# of '1', you enter '1',        |
|    but if you want to refresh your 3rd MN, which you   |
| have assigned a ID# of '3', you would enter '3' below. |
|                                                        |
|  If you used an a different naming convention than the |
|    sequential one described above, then follow that.   |
|                                                        |
| It's assumed that your MN(s) were installed under root |
|                                                        |::
+--------------------------------------------------------+::
:::::::::::::::::::::::::::::::::::::::::::::::::::::::
"
sleep 5
echo ""
read -rp "Press Ctrl-C to abort or any other key to continue. " -n1 -s
clear

# Check if we are root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root." 1>&2
   exit 1
fi


while ! [ "$MNID" -eq "$MNID" ] 2> /dev/null
do
  MNarray[0]=0 #not used
  MNarray[1]=1 #MN1 (the original MN)
  echo "Enter the single digit Masternode ID# for the MN you want to refresh."
  echo "MNIDs for active masternodes detected on this VPS are:"
  #it is assumed that at least the initial masternode is installed
  echo "1"
  for (( i = 2; i < 10; i++ )); do
      FILE=/etc/systemd/system/guapcoin$i.service
      if test -f "$FILE"; then
          MNarray[$i]=1
          echo "$i"
      fi
  done
  echo ""
  read -e -p "(e.g. If you are refreshing your inital MN, enter '1'; Refreshing MN2, enter '2'; MN3, '3'; You get it.) : " MNID

  # Make sure that $MNID is a number
  if ! [ "$MNID" -eq "$MNID" ] 2> /dev/null
  then
      echo ""
      echo "Sorry, the ID# must be a single digit integer corresponding to the MNID you want to refresh"
      read -rp "Press any key to continue. " -n1 -s
      clear

  fi

echo "Your chosen MNID is: $MNID"
echo test printing MNarray[2]: ${MNarray[2]}
echo test printing MNarray[MIND]: ${MNarray["$MNID"]}
  # Make sure that the masternode ID chosen corresponds to a MN installed on this VPS. Check for a corresponding guapcoin directory
if ! [ "${MNarray[$MNID]}" == "1" ] 2> /dev/null
then
  #statements
  echo "Sorry, the ID you've chosen does not correspond to a MNID detected on this VPS."
  read -rp "Press any key to continue and chose another. " -n1 -s
  MNID=""
fi

done
