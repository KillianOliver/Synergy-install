#!/bin/bash
# Script de configuration initiale des validateurs Synergy
echo "________________________________________"
echo "||| Configuration du serveur Synergy |||"
echo "----------------------------------------"
echo "Quel port souhaitez vous utilisez pour vos noeuds validateurs (entre 49152 et 65535) ?"
read port
echo "Vous avez choisi le port : $port"
echo "Nom d'utilisateur souhaité ?"
read username
echo "Mot de passe souhaité pour $username ?"
read mdp
echo "Clé public de votre SSH ?"
read sshpublickey
echo "Choix du réseau d'installation (mainnet, devnet, testnet) ?"
read typeofvalidator
echo "Nombre de validateur à installer ?"
read nbvalidator
sudo sed -i "s/#Port 22/Port $port/" /etc/ssh/sshd_config
yes | sudo ufw reset
sudo sed -i 's/IPV6=yes/IPV6=no/' /etc/default/ufw
sudo ufw allow $port
sudo ufw allow 37373:38383/tcp
yes | sudo ufw enable
sudo ufw status
sudo service ssh restart
sudo apt update
yes | sudo apt upgrade
sudo timedatectl set-timezone Europe/Paris

sudo useradd -s /bin/bash -d /home/killian -m -G sudo $username

echo -e "$mdp\n$mdp" | sudo passwd $username
echo "$username ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee "/etc/sudoers.d/myOverrides"
echo $mdp | su –l $username
mkdir -p $HOME/.ssh
echo $sshpublickey >> ~/.ssh/authorized_keys
sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
echo "AllowUsers $username" | sudo tee "/etc/ssh/sshd_config"
sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo service ssh restart
yes | sudo apt install git-all
sudo apt-get install zip unzip
cd ~
git clone https://github.com/ElrondNetwork/elrond-go-scripts
cd ~/elrond-go-scripts/config

sudo sed -i "s/ubuntu/$username/g" ~/elrond-go-scripts/config/variables.cfg
sudo sed -i "s/22/$port/g" ~/elrond-go-scripts/config/variables.cfg
sudo sed -i "s/ENVIRONMENT=\"\"/ENVIRONMENT=\"$typeofvalidator\"/" ~/elrond-go-scripts/config/variables.cfg
echo "$nbvalidator" >> validatorsinstall
for i in {0. .$nbvalidator. .1}
do
echo "Synergy-00$nbvalidator" >> validatorsinstall
done
~/elrond-go-scripts/script.sh install < validatorsinstall
cd ~
mkdir -p ~/VALIDATOR_KEYS
for i in {0. .$nbvalidator. .1}
do
./elrond-utils/keygenerator
zip node-$nbvalidator.zip validatorKey.pem
mv node-$nbvalidator.zip $HOME/VALIDATOR_KEYS/
mv validatorKey.pem $HOME/elrond-nodes/node-$nbvalidator/config/
done


echo "____________________________________________________________"
echo "Configuration de base terminé"
echo "Résumé de configuration ->"
echo "Port : $port"
echo "Utilistateur : $username"
echo "Mot de passe: $mdp"
echo "Clé SSH : $sshpublickey"
echo "Réseau : $typeofvalidator"
echo "Nombre de noeud installé : $nbvalidator"
echo "Liste des noeuds :"
for i in {0. .$nbvalidator. .1}
do
echo "Synergy-00$nbvalidator"
done
echo "reboot du serveur en cours.."