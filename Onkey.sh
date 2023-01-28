#!/bin/bash
set -x

dos2unix map.csv
hostname=`hostname -I`
nodename=`awk -F, -v IP=$hostname '$1==IP {print($2)}' map.csv`

echo 'export IRONFISH_WALLET='${nodename} >> $HOME/.bash_profile
echo 'export IRONFISH_NODENAME='${nodename} >> $HOME/.bash_profile
echo 'export IRONFISH_THREADS='-1 >> $HOME/.bash_profile

source .bash_profile
if [ ! $IRONFISH_NODENAME ]; then
 echo "nodename not config, exit"
 exit 1
fi
wget -q -O ironfish.sh https://raw.githubusercontent.com/fabius8/ironfish/main/ironfish.sh && echo 1 | ./ironfish.sh >/dev/null 2>&1 && unalias ironfish 2>/dev/null

service ironfishd stop;sleep 5;echo -e "Y\n" | ironfish chain:download;

service ironfishd start; sleep 30; ironfish config:set enableTelemetry true;

set +x
while true;
do
  if ironfish status | grep "(SYNCED)"; then
    break;
  else
    sleep 1
  fi
done

sleep 300

echo -e "\n" | ironfish faucet; sleep 5;  echo -e "\n" | ironfish faucet;
sleep 60;
ironfish wallet:balances

while true;
do
  balance=`ironfish wallet:balance | grep Balance | cut -f3 -d' '`
  if [ $balance == "0.00000000" ]; then
      sleep 10
      echo "............"
  else
     echo "balance: $balance"
     break;
  fi
done

ironfish wallet:mint --metadata=$(ironfish config:get nodeName|sed 's/\"//g') --name=$(ironfish config:get nodeName|sed 's/\"//g')  --amount=1000 --fee=0.00000001 --confirm;

for i in $(seq 1 60); do echo -ne ".";sleep 5;done;

while true;
do
  balance=`ironfish wallet:balance | grep Balance | cut -f3 -d' '`
  if [ $balance == "0.00000000" ]; then
      sleep 10
      echo "............"
  else
     echo "balance: $balance"
     break;
  fi
done

ironfish wallet:burn --assetId=$(ironfish wallet:balances | grep "$(ironfish config:get nodeName|sed 's/\"//g') " | awk '{print $2}')  --amount=1 --fee=0.00000001 --confirm;

for i in $(seq 1 60); do echo -ne ".";sleep 5;done;

while true;
do
  balance=`ironfish wallet:balance | grep Balance | cut -f3 -d' '`
  if [ $balance == "0.00000000" ]; then
      sleep 10
      echo "............"
  else
     echo "balance: $balance"
     break;
  fi
done

ironfish wallet:send --assetId=$(ironfish wallet:balances | grep "$(ironfish config:get nodeName|sed 's/\"//g') " | awk '{print $2}') --fee=0.00000001 --amount=1 --to=dfc2679369551e64e3950e06a88e68466e813c63b100283520045925adbe59ca --confirm
