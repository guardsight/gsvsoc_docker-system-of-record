#!/bin/bash
sudo apt update
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common 
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - 
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update 
sudo apt-get install -y git jq docker-ce 
sudo curl -L "https://github.com/docker/compose/releases/download/1.26.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose 
sudo chmod +x /usr/local/bin/docker-compose 
sudo mkdir -p /opt/secops 
sudo mkdir -p /logs/HOSTS 
sudo sysctl -w vm.max_map_count=262144
sudo groupadd -g 1111 logs 
sudo useradd -u 1111 -g 1111 logs 
sudo chown -R logs:logs /logs 
sudo chmod -R 750 /logs 
sudo chown logs:logs /opt/secops 
sudo chmod 770 /opt/secops 
sudo usermod -aG logs $(whoami)
newgrp logs
cd /opt/secops 
git clone https://github.com/guardsight/gsvsoc_docker-system-of-record.git 
cd /opt/secops/gsvsoc_docker-system-of-record 
sudo cp /opt/secops/gsvsoc_docker-system-of-record/99-infosec.sh /etc/profile.d/
sudo chmod +x /etc/profile.d/99-infosec.sh
sudo cp /opt/secops/gsvsoc_docker-system-of-record/cronjobs/daily/* /etc/cron.daily/
