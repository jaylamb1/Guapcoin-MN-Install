#!/bin/bash

#This script should be called with text file as an argument:
# e.g sudo /root/ChkGuapHoldingsv3.sh /root/file.text /root/ouput.text

#The text file should have the GUAP addresses you want to check the amounts for and a corresponding label for each address
#Format for the text should be:
#     Label1<space>GUAP Address1
#     Label2<space>GUAP Address2

#Make all variable available as environment variables
set -a

echo ""
echo "                   [GUAP Holdings Snaphot]                       "
echo "-----------------------------------------------------------------"

#Print timestamp in Day Date(MM-DD-YYYY) Time(HH:MMam) Timezone format
#d_epoch=$(TZ=":US/Eastern" date +"%s")
d=$(TZ=":US/Eastern" date +"%s")
d_formatted=$(TZ=":US/Eastern" date -d @$d +'%a %m-%d-%Y %I:%M:%S%P EST')

echo "Timestamp : $d_formatted"
echo ""
#echo "Test d: $d"
#Create arrays to hold GUAP addresses and address labels from file
declare -a MNArray
declare -a MNLabelArray

#capture the external file
filename=$1

#Clean up the file, remove bash comments and empty lines (creates a backup before removal)
sed -i".bkup" 's/^#.*$//' $filename #remove comments
sed -i '/^$/d' $filename #remove empty lines

#While loop to read in each GUAP address and corresponding label
n=0
while read label address; do
# reading each line
MNLabelArray[$n]=$label
MNArray[$n]=$address
n=$((n+1))
done < $filename

LastGuapTime='0'
LastGuapTotal='0'

#Read in GUAPtotals and timestamps from output2.text
LastGuapFile="/root/output2.text"

#Clean up the file, remove bash comments and empty lines (creates a backup before removal)
sed -i".bkup" 's/^#.*$//' $LastGuapFile #remove comments
sed -i '/^$/d' $LastGuapFile #remove empty lines

#Create arrays to hold GUAP totals and timestampsfrom file
declare -a GuapTotalArray
declare -a GuapChkArray


#get array of all recorded GUAP totals and timestamps
y=0
if test -f "$LastGuapFile"; then
  while read check total; do
    # reading each line
    GuapChkArray[$y]=$check
    GuapTotalArray[$y]=$total
    y=$((y+1))
  done < $LastGuapFile
fi


#Define function to find closest value in GuapChkArray using embedded python function
#Convert GuapChkArray from bash array to string usable by python
export GuapChkArrayList=${GuapChkArray[0]}
export TestDate="1579016427"
export UserDate=""
for i in ${GuapChkArray[@]:1}; do
  GuapChkArrayList+=,$i
done

echo "$GuapChkArrayList"

function find_closest {
python - <<END
import os
#convert string to python list
lst = os.environ['GuapChkArrayList']
lst = list(lst.split(","))


date = int(os.environ['UserDate'])
print lst[min(range(len(lst)), key = lambda i: abs(int(lst[i])-date))]

END
}

#ClosestDate=$(find_closest)
#echo $ClosestDate




#echo "Test GuapChkArray[0]=${GuapChkArray[0]}"
#echo "Test GuapTotalArray[0]=${GuapTotalArray[0]}"

#get last recorded GUAP total and time of check
if test -f "$LastGuapFile"; then
  while read -r time total; do
    LastGuapTime=$time
    LastGuapTotal=$total
    #echo "Test LastGuapTime = $LastGuapTime"
    #echo "Test LastGuapTotal = $LastGuapTotal"
  done < $LastGuapFile
fi


echo ""


echo "[Label]      [Address]                                [Subtotal] "
echo "-----------------------------------------------------------------"

echo ""

#For loop to get the current amount of GUAP in each saved GUAP address and print out each address, with its label and its GUAP amount
n=0
for i in "${MNArray[@]}"
do

  parm="http://159.65.221.180:3001/ext/getbalance/$i"
  Addr[$n]=$(curl -s -X GET $parm)
  tempVar=${Addr[$n]}
  tempLabel=${MNLabelArray[$n]}
  echo "  $tempLabel        $i : $(python -c 'import os; print "{0:>14,.3f}".format(float(os.environ["tempVar"]))')"
  echo ""

  ((++n))
done

#Var to hold the total amount of GUAP from all saved GUAP addresses, and For loop to iterate through MNArray and calculate the total of all the addresses
MN_Total=0
n=0
#Add everything up
for i in "${Addr[@]}"
do
  tempVar=${Addr[$n]}

  MN_Total=$(python -c 'import os; print "{:>14.3f}".format((float(os.environ["MN_Total"]) + float(os.environ["tempVar"])))')

  ((++n))
done

#Get total current GUAP chain money supply
parm7="http://159.65.221.180:3001/ext/getmoneysupply"

GUAPTotal=$(curl -s -X GET $parm7)

#Get percentage of total GUAP money suppy held by the addressed evaluated
Perc=$(python -c 'import os; print "{:>13,.2f}".format((float(os.environ["MN_Total"]) / float(os.environ["GUAPTotal"]) * 100))')

#Print out total holding and total GUAP money supply
echo "-----------------------------------------------------------------"
echo "  Total Current GUAP Holdings                   : $(python -c 'import os; print "{0:>14,.3f}".format(float(os.environ["MN_Total"]))')"

#Save MN_Total and timestamp to file output.text
echo -e "$d $MN_Total" >> /root/output2.text
echo ""
echo "-----------------------------------------------------------------"

DateVar=""
#Request date from user
echo "Please a date (in mm/dd/yyyy format), or number of days in the "
read -e -p "past, from which to calculate GUAP earn rate : " DateVar

if date=$(date -d "$DateVar" +'%m/%d/%Y'); then
  # user date was ok
  echo $date


GUAPearned=$(python -c 'import os; print "{0:,.0f}".format((float(os.environ["MN_Total"]) - float(os.environ["LastGuapTotal"])))')
GUAPearnedNoComma=$(python -c 'import os; print "{0:.0f}".format((float(os.environ["MN_Total"]) - float(os.environ["LastGuapTotal"])))')
#TimeElapsed=$((d_epoch-LastGuapTime))
d_var=$(TZ=":US/Eastern" date -d @$d +'%Y-%m-%dT%H:%M:%S')
LastGuapTime_var=$(TZ=":US/Eastern" date -d @$LastGuapTime +'%Y-%m-%dT%H:%M:%S')


TimeElapsed=$(dateutils.ddiff $d_var $LastGuapTime_var -f '%dd:%Hh:%Mm:%Ss')

echo "  Last check @ $(TZ=":US/Eastern" date -d  @$LastGuapTime +'%m/%d %I:%M:%S%P') EST"

#Remove thousands comma from GUAPearned variable
#GUAPearned=$(python -c 'import os; print "{0:.0f}".format(float(os.environ["GUAPearned"]))')

echo "  GUAP earned since:  $GUAPearned GUAP in last $TimeElapsed"

TimeElapsedSec=$(dateutils.ddiff $d_var $LastGuapTime_var -f '%S')
TimeElapsedMin=$(dateutils.ddiff $d_var $LastGuapTime_var -f '%M')
TimeElapsedHr=$(dateutils.ddiff $d_var $LastGuapTime_var -f '%H')

if [[ $TimeElapsedHr > '0' ]]; then
  #echo "TimeElapsedHr = $TimeElapsedHr"
  #echo "TimeElapsedHr >0"
  GUAPearnRateH=$(python -c 'import os; print "{:10.8f}".format(abs((float(os.environ["GUAPearnedNoComma"]) / (float(os.environ["TimeElapsedSec"])/3600))))')
  echo "  Earn rate/hr     :  $GUAPearnRateH GUAP/hour"
fi

if [[ $TimeElapsedMin > '0' ]]; then
  #echo "TimeElapsedMin = $TimeElapsedMin"
  #echo "TimeElapsedMin > 0"
  GUAPearnRateM=$(python -c 'import os; print "{:10.8f}".format(abs((float(os.environ["GUAPearnedNoComma"]) / (float(os.environ["TimeElapsedSec"])/60))))')
  echo "  Earn rate/min    :  $GUAPearnRateM GUAP/minute"
fi


#TimeElapsedMin=$(python -c 'import os; print "{:10.8f}".format(abs((float(os.environ["GUAPearned"]) / 60)))')
#TimeElapsedHr=$(python -c 'import os; print "{:10.8f}".format(abs((float(os.environ["GUAPearned"]) / 3600)))')

#echo "TimeElapsedSec=$TimeElapsedSec"


#  GUAPearnRateH=$(python -c 'import os; print "{:10.8f}".format(abs((float(os.environ["GUAPearned"]) / float(os.environ["TimeElapsedHr"]))))')
#  GUAPearnRateM=$(python -c 'import os; print "{:10.8f}".format(abs((float(os.environ["GUAPearned"]) / float(os.environ["TimeElapsedMin"]))))')
  GUAPearnRateS=$(python -c 'import os; print "{:10.8f}".format(abs((float(os.environ["GUAPearnedNoComma"]) / float(os.environ["TimeElapsedSec"]))))')

#  echo "  Earn rate        :  [$GUAPearnRateH GUAP/hour   ]"
#  echo "                   :  [$GUAPearnRateM GUAP/minute ]"
#  echo "                   :  [$GUAPearnRateS GUAP/second ]"
echo "  Earn rate/sec    :  $GUAPearnRateS GUAP/second"


echo "-----------------------------------------------------------------"
echo ""
echo "Total GUAP Money Supply                         : $(python -c 'import os; print "{0:>14,.3f}".format(float(os.environ["GUAPTotal"]))')"

echo ""
#Get total number of GUAP masternodes and do some formating
parm8="http://159.65.221.180:3001/ext/getmasternodecount"
MNCount=$(curl -s -X GET $parm8)

#Removes random whitespace from beginning of MNCount
shopt -s extglob
MNCount=${MNCount##*( )}
shopt -u extglob
#right justify
MNCount=$(printf '%14s' $MNCount)

#Get percentage of total GUAP voting power
#decrease n variable because of the 2 change addresses we are tracking
n=$((n-2))
#Perc2=$(python -c 'import os; print "{:>13,.0f}".format((float(os.environ["MN_Total"]) / float(os.environ["MNCount"]) * 100))')


#Get current block count/height
parm9="http://159.65.221.180:3001/api/getblockcount"
BlockHeight=$(curl -s -X GET $parm9)
BlockHeight=$(printf '%14s' $BlockHeight)

#Print out percentage of GUAP money supply, Masternode count, and GUAP chain block count/height
echo "Percentage of total GUAP Money Supply           : $Perc%"
echo ""

echo "Total number of GUAP masternodes                : $MNCount"
MNCount=$(python -c 'import os; print "{0:>14,.0f}".format(float(os.environ["MNCount"]))')
n=$(python -c 'import os; print "{0:>14,.0f}".format(float(os.environ["n"]))')
echo ""
Perc2=$(python -c 'import os; print "{:>13,.2f}".format((float(os.environ["n"]) / float(os.environ["MNCount"]) * 100))')

echo "Percentage of total GUAP Voting Power           : $Perc2%"
echo ""
echo "GUAP Chain Block Count                          : $BlockHeight"
echo ""



#Turn off environment variables
set +a
