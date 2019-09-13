#!/bin/bash

#Make all variable available as environment variables
set -a

echo ""
echo "                   [GUAP Holdings Snaphot]                       "
echo "-----------------------------------------------------------------"

# Print timestamp in Day Date(MM-DD-YYYY) Time(HH:MMam) format
d=$(TZ=":US/Eastern" date +'%a %m-%d-%Y %I:%M%P EST')
echo "Timestamp : $d"
echo ""


declare -a MNArray
declare -a MNLabelArray

filename=$1
n=0
while read label address; do
# reading each line
#echo "$label $address"
MNLabelArray[$n]=$label
MNArray[$n]=$address
n=$((n+1))
done < $filename

#echo ""
echo ""

n=0
echo "[Label]      [Address]                                [Subtotal] "
echo "-----------------------------------------------------------------"

echo ""

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


MN_Total=0
n=0
#Add everything up
for i in "${Addr[@]}"
do
  tempVar=${Addr[$n]}

  MN_Total=$(python -c 'import os; print "{:>14.3f}".format((float(os.environ["MN_Total"]) + float(os.environ["tempVar"])))')

  ((++n))
done



parm7="http://159.65.221.180:3001/ext/getmoneysupply"

GUAPTotal=$(curl -s -X GET $parm7)


Perc=$(python -c 'import os; print "{:>13,.2f}".format((float(os.environ["MN_Total"]) / float(os.environ["GUAPTotal"]) * 100))')
echo "-----------------------------------------------------------------"
echo "  Total GUAP Holdings                           : $(python -c 'import os; print "{0:>14,.3f}".format(float(os.environ["MN_Total"]))')"

echo "-----------------------------------------------------------------"
echo "-----------------------------------------------------------------"
echo ""
echo "Total GUAP Money Supply                         : $(python -c 'import os; print "{0:>14,.3f}".format(float(os.environ["GUAPTotal"]))')"

echo ""
parm8="http://159.65.221.180:3001/ext/getmasternodecount"
MNCount=$(curl -s -X GET $parm8)
shopt -s extglob
MNCount=${MNCount##*( )}
shopt -u extglob
MNCount=$(printf '%14s' $MNCount)



parm9="http://159.65.221.180:3001/api/getblockcount"
BlockHeight=$(curl -s -X GET $parm9)
BlockHeight=$(printf '%14s' $BlockHeight)

echo "Percentage of total GUAP Money Supply           : $Perc%"
echo ""
echo "Total number of GUAP masternodes                : $MNCount"
echo ""
echo "GUAP Chain Block Count                          : $BlockHeight"
echo ""

#Turn off environment variables
set +a
