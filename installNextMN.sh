#!/bin/bash

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

MNID=""

case $key in
    -a|--advanced)
    ADVANCED="y"
    shift
    ;;
    -n|--normal)
    ADVANCED="n"
    FAIL2BAN="y"
    UFW="y"
    BOOTSTRAP="y"
    shift
    ;;
    -i|--externalip)
    EXTERNALIP="$2"
    ARGUMENTIP="y"
    shift
    shift
    ;;
    -k|--privatekey)
    KEY="$2"
    shift
    shift
    ;;
    -f|--fail2ban)
    FAIL2BAN="y"
    shift
    ;;
    --no-fail2ban)
    FAIL2BAN="n"
    shift
    ;;
    -u|--ufw)
    UFW="y"
    shift
    ;;
    --no-ufw)
    UFW="n"
    shift
    ;;
    -b|--bootstrap)
    BOOTSTRAP="y"
    shift
    ;;
    --no-bootstrap)
    BOOTSTRAP="n"
    shift
    ;;
    -h|--help)
    cat << EOL
GUAP Masternode installer arguments:
    -n --normal               : Run installer in normal mode
    -a --advanced             : Run installer in advanced mode
    -i --externalip <address> : Public IP address of VPS
    -k --privatekey <key>     : Private key to use
    -f --fail2ban             : Install Fail2Ban
    --no-fail2ban             : Don't install Fail2Ban
    -u --ufw                  : Install UFW
    --no-ufw                  : Don't install UFW
    -b --bootstrap            : Sync node using Bootstrap
    --no-bootstrap            : Don't use Bootstrap
    -h --help                 : Display this help text.
EOL
    exit
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

clear


#!/bin/bash

# Check if we are root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root." 1>&2
   exit 1
fi

# Check for systemd
systemctl --version >/dev/null 2>&1 || { echo "systemd is required. Are you using Ubuntu 16.04?"  >&2; exit 1; }

# CHARS is used for the loading animation further down.
CHARS="/-\|"
if [ -z "$EXTERNALIP" ]; then
EXTERNALIP=`dig +short myip.opendns.com @resolver1.opendns.com`
fi
clear

if [ -z "$ADVANCED" ]; then
echo "
    ___T_
   | o o |
   |__-__|
   /| []|\\
 ()/|___|\()
    |_|_|
    /_|_\  ------- EXTRA MASTERNODE INSTALLER v1 -------+
 |                                                        |
 |     This script will install an additional MN.         |
 |                                                        |
 |  If you have NOT ALREADY INSTALLED a first MN on this  |
 |   VPS using the standard Guapcoin-MN-Install script,   |
 |          then this installer is not for you.           |
 |                                                        |
 |  It is assumed that at least one MN has been installed |
 |    on this VPS and that the guapcoin executables in    |
 |    /usr/local/bin are in place and are operational.    |
 |                                                        |
 |  It is also assumed that this VPS is setup with a new  |
 |      static IP which will be used for this new MN,     |
 |     and that the interface for the new IP is active.   |
 |   See your VPS documentation on additional static IP.  |
 |                                                        |
 |           -------------------------------              |
 |                                                        |
 |   You can choose between two installation options:     |::
 |              default and advanced.                     |::
 |                                                        |::
 |  The advanced installation will install and run        |::
 |   the masternode under a non-root user. If you         |::
 |   don't know what that means, use the default          |::
 |               installation method.                     |::
 |                                                        |::
 |  Otherwise, your masternode will not work, and         |::
 | the GUAP Team CANNOT assist you in repairing           |::
 |         it. You will have to start over.               |::
 |                                                        |::
 +--------------------------------------------------------+::
   :::::::::::::::::::::::::::::::::::::::::::::::::::::::
"

sleep 5
fi

if [ -z "$ADVANCED" ]; then
read -e -p "Use the Advanced Installation? [N/y] : " ADVANCED
fi

if [[ ("$ADVANCED" == "y" || "$ADVANCED" == "Y") ]]; then

USER=guapcoin

adduser $USER --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --disabled-password > /dev/null

INSTALLERUSED="#Used Advanced Install"

echo "" && echo 'Added user "guapcoin"' && echo ""
sleep 1

else

USER=root
FAIL2BAN="y"
UFW="y"
BOOTSTRAP="n"
INSTALLERUSED="#Used Basic Install"
fi

USERHOME=`eval echo "~$USER"`

if [ -z "$ARGUMENTIP" ]; then
read -e -p "Server IP Address (Ensure that you enter the new static IP): " -i $EXTERNALIP -e IP
fi

if [ -z "$KEY" ]; then
read -e -p "Masternode Private Key (e.g. 7edfjLCUzGczZi3JQw8GHp434R9kNY33eFyMGeKRymkB56G4324h # THE KEY YOU GENERATED EARLIER) : " KEY
fi

if [ -z "$MNID" ]; then
read -e -p "Enter a single digit number for this Masternode's ID#. It must not match the ID# of an existing MN on this VPS (e.g. second MN? enter '2') : " MNID
fi

if [ -z "$FAIL2BAN" ]; then
read -e -p "Install Fail2ban? [Y/n] : " FAIL2BAN
fi

if [ -z "$UFW" ]; then
read -e -p "Install UFW and configure ports? [Y/n] : " UFW
fi

if [ -z "$BOOTSTRAP" ]; then
read -e -p "Do you want to use our bootstrap file to speed the syncing process? [Y/n] : " BOOTSTRAP
fi

clear

# Generate random passwords
RPCUSER=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1)
RPCPASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)





#*********************** Assumes additional Masternode is being created; creates a .guapcoin$MNID dir and sets up the guapcoin$MNID.service *****************************************************


# Create .guapcoin$MNID directory
mkdir $USERHOME/.guapcoin$MNID

# Install bootstrap file
if [[ ("$BOOTSTRAP" == "y" || "$BOOTSTRAP" == "Y" || "$BOOTSTRAP" == "") ]]; then
  echo "skipping"
fi

# Create guapcoin.conf in new guapcoin$MNID hidden dir; setup guapcoin$MNID.service
touch $USERHOME/.guapcoin$MNID/guapcoin.conf
cat > $USERHOME/.guapcoin$MNID/guapcoin.conf << EOL
${INSTALLERUSED}
rpcuser=${RPCUSER}
rpcpassword=${RPCPASSWORD}
rpcallowip=127.0.0.1
rpcport=5000$MNID
listen=1
server=1
daemon=1
staking=1
logtimestamps=1
maxconnections=256
externalip=${IP}
bind=${IP}:9633
masternodeaddr=${IP}
masternodeprivkey=${KEY}
masternode=1
addnode=159.65.221.180
addnode=165.227.192.223
addnode=159.65.217.114
addnode=165.227.83.244
EOL
chmod 0600 $USERHOME/.guapcoin$MNID/guapcoin.conf
chown -R $USER:$USER $USERHOME/.guapcoin$MNID

sleep 1

cat > /etc/systemd/system/guapcoin$MNID.service << EOL
[Unit]
Description=guapcoind
After=network.target
[Service]
Type=forking
User=$USER
Group=$USER
WorkingDirectory=$USERHOME/.guapcoin$MNID
ExecStart=/usr/local/bin/guapcoind -conf=guapcoin.conf -datadir=$USERHOME/.guapcoin$MNID
ExecStop=/usr/local/bin/guapcoin-cli -conf=guapcoin.conf -datadir=$USERHOME/.guapcoin$MNID stop
Restart=on-abort
[Install]
WantedBy=multi-user.target
EOL
sudo systemctl enable guapcoin$MNID.service
echo "Starting guapcoin$MNID service"

sudo systemctl start guapcoin$MNID.service

echo "Waiting for guapcoin$MNID wallet to load..."
until su -c "/usr/local/bin/guapcoin-cli getinfo 2>/dev/null | grep -q \"version\"" $USER; do
  sleep 1;
done

clear

echo "Your masternode is syncing. Please wait for this process to finish."
echo "This step can take up to a few hours. Do not close this window."

echo ""

until su -c "/usr/local/bin/guapcoin-cli mnsync status 2>/dev/null | grep '\"IsBlockchainSynced\": true' > /dev/null" "$USER"; do
  echo -ne "Current block: $(su -c "/usr/local/bin/guapcoin-cli getblockcount" "$USER")\\r"
  sleep 1
done
echo "SYNC complete!"
sleep 3
clear

echo "Your wallet is loaded at /$USERHOME/.guapcoin$MNID, and synce has completed for the new Masternode$MNID"
sleep 7


clear

cat << EOL
Now, you need to start your masternode. Follow the steps below:
1) Please go to your desktop wallet
2) Click the Masternodes tab
3) Click 'Start all' at the bottom or select your new node and click 'Start Alias'.
EOL

read -p "Press Enter to continue after you've done that. " -n1 -s

clear

echo "" && echo "Masternode$MNID setup completed." && echo ""
echo "" && echo "Please see details for the new Masternode$MNID below:"
echo -ne "$(su -c "/usr/local/bin/guapcoin-cli -conf=/root/.guapcoin$MNID/guapcoin.conf -datadir=/root/.guapcoin$MNID masternode status" "$USER")\\r"
