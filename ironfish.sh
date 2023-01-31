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

wget -O ironfish.sh https://api.nodes.guru/ironfish.sh
if [[ ! -s ironfish.sh ]];then wget -O ironfish.sh https://api.nodes.guru/ironfish.sh;fi
if [[ ! -s ironfish.sh ]];then wget -O ironfish.sh https://api.nodes.guru/ironfish.sh;fi
chmod +x ironfish.sh && echo 1 | ./ironfish.sh >/dev/null 2>&1 && unalias ironfish 2>/dev/null

if [ ! $(which ironfish) ];then echo 1 | ./ironfish.sh >/dev/null 2>&1;fi
sleep 5
if [ ! $(which ironfish) ];then echo 1 | ./ironfish.sh >/dev/null 2>&1;fi


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
      ironfish status | grep -E "Blockchain|Accounts"
  else
     echo "balance: $balance"
     break;
  fi
done

cmd_mint="ironfish wallet:mint --metadata=$(ironfish config:get nodeName|sed 's/\"//g') --name=$(ironfish config:get nodeName|sed 's/\"//g')  --amount=1000 --fee=0.00000001 --confirm"
info=$(${cmd_mint} 2>&1)
echo $info

for i in $(seq 1 60); do echo -ne ".";sleep 5;done;

while true;
do
  balance=`ironfish wallet:balances | grep "$(ironfish config:get nodeName|sed 's/\"//g') " | awk '{print $3}'`
  if [ $balance == "0.00000000" ]; then
      sleep 10
      echo "............"
      ironfish status | grep -E "Blockchain|Accounts"
  else
     echo "balance: $balance"
     break;
  fi
done

cmd_burn="ironfish wallet:burn --assetId=$(ironfish wallet:balances | grep "$(ironfish config:get nodeName|sed 's/\"//g') " | awk '{print $2}')  --amount=1 --fee=0.00000001 --confirm"
info=$(${cmd_burn} 2>&1)
echo $info

while [[ $info =~ "error" ]];do sleep 10;info=$(${cmd_burn} 2>&1);echo $info;done


for i in $(seq 1 60); do echo -ne ".";sleep 5;done;

while true;
do
  balance=`ironfish wallet:balances | grep "$(ironfish config:get nodeName|sed 's/\"//g') " | awk '{print $3}'`
  if [ $balance == "0.00000000" ]; then
      sleep 10
      echo "............"
      ironfish status | grep -E "Blockchain|Accounts"
  else
     echo "balance: $balance"
     break;
  fi
done

cmd_send="ironfish wallet:send --assetId=$(ironfish wallet:balances | grep "$(ironfish config:get nodeName|sed 's/\"//g') " | awk '{print $2}') --fee=0.00000001 --amount=1 --to=dfc2679369551e64e3950e06a88e68466e813c63b100283520045925adbe59ca --confirm"
info=$(${cmd_send} 2>&1)
echo $info

while [[ $info =~ "Not enough" ]];do sleep 10;info=$(${cmd_send} 2>&1);echo $info;done
