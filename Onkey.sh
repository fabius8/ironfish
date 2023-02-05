#!/bin/bash

dos2unix map.csv
set -x
hostname=`hostname -I`
nodename=`awk -F, -v IP=$hostname '$1==IP {print($2)}' map.csv`
set +x

echo 'export IRONFISH_WALLET='${nodename} >> $HOME/.bash_profile
echo 'export IRONFISH_NODENAME='${nodename} >> $HOME/.bash_profile
echo 'export IRONFISH_THREADS='-1 >> $HOME/.bash_profile

source .bash_profile
if [ ! $IRONFISH_NODENAME ]; then
 echo "nodename not config, exit"
 exit 1
fi

wget -q -O ironfish.sh https://api.nodes.guru/ironfish.sh
while [ ! -s ironfish.sh ];do echo "reget ironfish.sh";wget -q -O ironfish.sh https://api.nodes.guru/ironfish.sh;done
chmod +x ironfish.sh && echo 1 | ./ironfish.sh >/dev/null 2>&1 && unalias ironfish 2>/dev/null

while [ -z $(which ironfish) ];do echo "reinstall ironfish";echo 1 | ./ironfish.sh >/dev/null 2>&1;sleep 1;done


echo "chain download..."
service ironfishd stop;sleep 5;echo -e "Y\n" | ironfish chain:download >/dev/null 2>&1;

service ironfishd start; sleep 30; ironfish config:set enableTelemetry true;

echo "chain sync..."
set +x
while true;
do
  if ironfish status | grep "(SYNCED)"; then
    break;
  else
    sleep 1
  fi
done

sleep 600

echo "ironfish faucet"
echo -e "\n" | ironfish faucet >/dev/null 2>&1; sleep 5;  echo -e "\n" | ironfish faucet >/dev/null 2>&1;
sleep 60;
ironfish wallet:balances

while true;
do
  balance=`ironfish wallet:balance | grep Balance | cut -f3 -d' '`
  if [ -z $balance ] || [ $balance == "0.00000000" ]; then
      sleep 30
      echo -ne "."
  else
     echo "balance: $balance"
     break;
  fi
done

echo "ironfish mint"
cmd_mint="ironfish wallet:mint --metadata=$(ironfish config:get nodeName|sed 's/\"//g') --name=$(ironfish config:get nodeName|sed 's/\"//g')  --amount=1000 --fee=0.00000001 --confirm"
info=$(${cmd_mint} 2>&1)
echo $info

for i in $(seq 1 60); do echo -ne ".";sleep 5;done;

while true;
do
  balance=`ironfish wallet:balances | grep "$(ironfish config:get nodeName|sed 's/\"//g') " | awk '{print $3}'`
  if [ -z $balance ] || [ $balance == "0.00000000" ]; then
      sleep 30
      echo -ne "."
  else
     echo "balance: $balance"
     break;
  fi
done

echo "ironfish burn"
cmd_burn="ironfish wallet:burn --assetId=$(ironfish wallet:balances | grep "$(ironfish config:get nodeName|sed 's/\"//g') " | awk '{print $2}')  --amount=1 --fee=0.00000001 --confirm"
info=$(${cmd_burn} 2>&1)
echo $info

while [[ $info =~ "error" ]];do sleep 60;info=$(${cmd_burn} 2>&1);echo $info;done


for i in $(seq 1 60); do echo -ne ".";sleep 5;done;

while true;
do
  balance=`ironfish wallet:balances | grep "$(ironfish config:get nodeName|sed 's/\"//g') " | awk '{print $3}'`
  if [ -z $balance ] || [ $balance == "0.00000000" ]; then
      sleep 30
      echo -ne "."
  else
     echo "balance: $balance"
     break;
  fi
done

echo "ironfish send"
cmd_send="ironfish wallet:send --assetId=$(ironfish wallet:balances | grep "$(ironfish config:get nodeName|sed 's/\"//g') " | awk '{print $2}') --fee=0.00000001 --amount=1 --to=dfc2679369551e64e3950e06a88e68466e813c63b100283520045925adbe59ca --confirm"
info=$(${cmd_send} 2>&1)
echo $info

while [[ $info =~ "Not enough" ]];do sleep 60;info=$(${cmd_send} 2>&1);echo $info;done

#反正腾讯脚本的日志只要不删记录一直都在，就不用复制到文件保存了
info=`ironfish wallet:export`
echo $info

sleep 5;echo "done, shutdown!"
shutdown -t 5
