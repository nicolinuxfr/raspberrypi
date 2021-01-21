#!/bin/bash

# Ce script doit être exécuté sur un Raspberry Pi, avec Raspberry Pi OS Lite.
# PENSEZ À L'ADAPTER EN FONCTION DE VOS BESOINS

GIT='/home/pi/config'

locale-gen "en_US.UTF-8"
timedatectl set-timezone Europe/Paris

cp -rf $GIT/et/hosts /etc/hosts
cp -rf $GIT/et/hostname /etc/hostname

echo "======== Mise à jour initiale ========"
apt update
apt -y upgrade
apt -y dist-upgrade
apt -y autoremove

echo "======== Installation des quelques outils ========"
apt -y install zsh git
sudo -u pi sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

ln -s $GIT/home/.alias ~/.alias
ln -sf $GIT/home/.zshrc ~/.zshrc

# Installation de log2ram pour soulager la carte SD

echo "deb http://packages.azlux.fr/debian/ buster main" | sudo tee /etc/apt/sources.list.d/azlux.list
wget -qO - https://azlux.fr/repo.gpg.key | sudo apt-key add -
apt -y update
apt -y install log2ram

ln -sf $GIT/etc/log2ram.conf /etc/log2ram.conf

echo "======== Installation de Homebridge ========"
# setup repo
curl -sL https://deb.nodesource.com/setup_12.x | sudo bash -

# install Node.js
apt install -y nodejs gcc g++ make python

# upgrade npm (version 6.13.4 has issues with git dependencies)
npm install -g npm

# Homebridge
npm install -g --unsafe-perm homebridge homebridge-config-ui-x
hb-service install --user homebridge --port 8080


echo "======== Installation de Caddy ========"
echo "deb [trusted=yes] https://apt.fury.io/caddy/ /" \
    | sudo tee -a /etc/apt/sources.list.d/caddy-fury.list
apt -y update
apt -y install caddy jq

cp -rf $GIT/etc/caddy/Caddyfile /etc/caddy/
chown caddy:caddy /etc/caddy/Caddyfile
chmod 444 /etc/caddy/Caddyfile

mkdir -p /var/log/caddy
chown -R caddy:caddy /var/log/caddy

mkdir -p /var/www/recettes/
chown -R pi:pi /var/www/

systemctl start caddy

echo "======== Installation de Ghost ========"
npm install ghost-cli@latest -g

cd /var/www/recettes/
ghost install local

systemctl enable $GIT/etc/systemd/ghost-recettes.service

echo "======== Installation de Pi-Hole et Unbound ========"

curl -sSL https://install.pi-hole.net | bash

cd /tmp
wget -O root.hints https://www.internic.net/domain/named.root
sudo mv root.hints /var/lib/unbound/

ln -sf $GIT/etc/unbound/unbound.conf.d/pi-hole.conf /etc/unbound/unbound.conf.d/

sudo service unbound start
dig pi-hole.net @127.0.0.1 -p 5335

echo "======== Redémarrage nécessaire ========"
echo "Le Raspberry Pi doit être redémarré pour appliquer les changements."