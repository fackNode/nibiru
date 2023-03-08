#!/bin/bash

curl -s "https://nodes.fackblock.com/api/logo.sh" | sh && sleep 2

fmt=`tput setaf 45`
end="\e[0m\n"
err="\e[31m"
scss="\e[32m"

echo -e "${fmt}\nSetting up dependencies / Устанавливаем необходимые зависимости${end}" && sleep 1

if ! go version; then
    sudo rm -rf /usr/local/go
    curl -Ls https://go.dev/dl/go1.19.5.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
    eval $(echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee /etc/profile.d/golang.sh)
    eval $(echo 'export PATH=$PATH:$HOME/go/bin' | tee -a $HOME/.profile)

if ! go version; then
    echo "${err}Installation of Go failed. Exiting.${end}" && sleep 1
    exit 1
fi

fi

if [ ! $NIBIRU_NAME ]; then
	echo -e "${err}You don't have node name! / Нету имени ноды! ${end}" && sleep 1
    exit 1

else
    echo -e "${fmt}Your node name - ${NIBIRU_NAME} ${end}" && sleep 1
fi

git clone https://github.com/NibiruChain/nibiru
cd nibiru
git checkout v0.19.2
make install


if ! nibid version; then
    echo "${err}Installation of Nibiru failed. Exiting.${end}" && sleep 1
    exit 1
fi

nibid init $NIBIRU_NAME --chain-id nibiru-itn-1

wget -O $HOME/.nibid/config/genesis.json "https://raw.githubusercontent.com/obajay/nodes-Guides/main/Nibiru/genesis.json"
#wget -O $HOME/.nibid/config/addrbook.json "https://ss-t.nibiru.nodestake.top/addrbook.json"
wget -O $HOME/.nibid/config/addrbook.json "https://share.utsa.tech/nibiru/addrbook.json"

nibid config chain-id nibiru-itn-1
nibid config keyring-backend os

sed -i.bak -e "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0.025unibi\"/;" ~/.nibid/config/app.toml
external_address=$(wget -qO- eth0.me)
sed -i.bak -e "s/^external_address *=.*/external_address = \"$external_address:26656\"/" $HOME/.nibid/config/config.toml

PEERS="e2b8b9f3106d669fe6f3b49e0eee0c5de818917e@213.239.217.52:32656,930b1eb3f0e57b97574ed44cb53b69fb65722786@144.76.30.36:15662,ad002a4592e7bcdfff31eedd8cee7763b39601e7@65.109.122.105:36656,4a81486786a7c744691dc500360efcdaf22f0840@15.235.46.50:26656,68874e60acc2b864959ab97e651ff767db47a2ea@65.108.140.220:26656,d5519e378247dfb61dfe90652d1fe3e2b3005a5b@65.109.68.190:39656"
SEEDS="a431d3d1b451629a21799963d9eb10d83e261d2c@seed-1.itn-1.nibiru.fi:26656,6a78a2a5f19c93661a493ecbe69afc72b5c54117@seed-2.itn-1.nibiru.fi:26656"
sed -i -e "s|^persistent_peers *=.*|persistent_peers = \"$PEERS\"|" $HOME/.nibid/config/config.toml
sed -i -e "s|^seeds *=.*|seeds = \"$SEEDS\"|" $HOME/.nibid/config/config.toml

sed -i 's/max_num_inbound_peers =.*/max_num_inbound_peers = 50/g' $HOME/.nibid/config/config.toml
sed -i 's/max_num_outbound_peers =.*/max_num_outbound_peers = 25/g' $HOME/.nibid/config/config.toml
sed -i -e "s/^filter_peers *=.*/filter_peers = \"true\"/" $HOME/.nibid/config/config.toml

pruning="custom"
pruning_keep_recent="1000"
pruning_interval="10"
sed -i -e "s/^pruning *=.*/pruning = \"$pruning\"/" $HOME/.nibid/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$pruning_keep_recent\"/" $HOME/.nibid/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$pruning_interval\"/" $HOME/.nibid/config/app.toml

snapshot_interval=1000
sed -i.bak -e "s/^snapshot-interval *=.*/snapshot-interval = \"$snapshot_interval\"/" ~/.nibid/config/app.toml

sudo tee /etc/systemd/system/nibid.service > /dev/null <<EOF
[Unit]
Description=nibid
After=network-online.target

[Service]
User=$USER
ExecStart=$(which nibid) start
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable nibid
systemctl restart nibid
