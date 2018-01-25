#!/bin/bash

if (whiptail --title "Setup OpenVPN" --yesno "You are about to configure your \
Raspberry Pi as a VPN server running OpenVPN. Are you sure you want to \
continue?" 8 78) then
 whiptail --title "Setup OpenVPN" --infobox "OpenVPN will be installed and \
 configured." 8 78
else
 whiptail --title "Setup OpenVPN" --msgbox "Cancelled" 8 78
 exit
fi

#DOWNLOAD/INSTALL OPENVPN & EASY-RSA
#Install openvpn
echo "Updating, Upgrading, and Installing..."
apt-get -y install openvpn

#Install easy-rsa - VERSION 2.x
#VER=2 # Easy-RSA version number
#cd /etc/openvpn
#mkdir easy-rsa
#wget https://github.com/OpenVPN/easy-rsa/archive/release/$VER.x.zip
#unzip $VER.x.zip
#rm $VER.x.zip
#cp -r /etc/openvpn/easy-rsa-release-$VER.x/easy-rsa/2.0/* /etc/openvpn/easy-rsa

#Install easy-rsa
cd /etc/openvpn
mkdir easy-rsa
wget https://github.com/OpenVPN/easy-rsa/archive/v3.0.5.zip
unzip v3.0.5.zip
rm v3.0.5.zip
cp -r /etc/openvpn/easy-rsa-3.0.5/easyrsa3 /etc/openvpn/easy-rsa
#Update command usage

#ACCEPT CONFIGURATION INPUT FROM USER
# Read username from the user
USER=$(whiptail --inputbox "Which user is the server to be run under?" \
8 78 --title "Setup OpenVPN" 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus = 0 ]; then
 whiptail --title "Setup OpenVPN" --infobox "User: $USER" 8 78
else
 whiptail --title "Setup OpenVPN" --infobox "Cancelled" 8 78
 exit
fi

#Read server's local IP address from the user
LOCALIP=$(whiptail --inputbox "What is your Raspberry Pi's local IP address?" \
8 78 --title "Setup OpenVPN" 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus = 0 ]; then
 whiptail --title "Setup OpenVPN" --infobox "Local IP: $LOCALIP" 8 78
else
 whiptail --title "Setup OpenVPN" --infobox "Cancelled" 8 78
 exit
fi

#Read server's public IP address from the user
PUBLICIP=$(whiptail --inputbox "What is the public IP address of network the \
Raspberry Pi is on?" 8 78 --title "OpenVPN Setup" 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus = 0 ]; then
 whiptail --title "Setup OpenVPN" --infobox "PUBLIC IP: $PUBLICIP" 8 78
else
 whiptail --title "Setup OpenVPN" --infobox "Cancelled" 8 78
 exit
fi

#Ask user for desired level of encryption
ENCRYPT=$(whiptail --title "Setup OpenVPN" --menu "Choose your desired level \
of encryption:" 8 78 2 \
"1024" "Use 1024-bit encryption. This is faster to set up, but less secure." \
"2048" "Use 2048-bit encryption. This is much slower to set up, but more secure." \
3>&2 2>&1 1>&3)


#EASY-RSA SETUP
cd /etc/openvpn/easy-rsa
cp vars vars.backup
sed -i 's:"`pwd`":"/etc/openvpn/easy-rsa":' vars
if [ $ENCRYPT = 1024 ]; then
 sed -i 's:KEY_SIZE=2048:KEY_SIZE=1024:' vars
fi

#Build the CA
source ./vars
./clean-all
./build-ca < /home/$USER/OpenVPN-Setup/ca_info.txt

whiptail --title "Setup OpenVPN" --msgbox "You will now be asked for identifying \
information for the server. Press 'Enter' to skip a field." 8 78
#Build server key pair
./build-key-server server

#Generate Diffie-Hellman exchange
./build-dh

#Generate HMAC key
openvpn --genkey --secret keys/ta.key

#SETUP OPENVPN SERVER
#Write config file for server using the template .txt file
sed 's/LOCALIP/'$LOCALIP'/' </home/$USER/OpenVPN-Setup/server_config.txt >/etc/openvpn/server.conf
if [ $ENCRYPT = 2048 ]; then
 sed -i 's:dh1024:dh2048:' /etc/openvpn/server.conf
fi

# Enable forwarding of internet traffic
sed -i '/#net.ipv4.ip_forward=1/c\
net.ipv4.ip_forward=1' /etc/sysctl.conf
sudo sysctl -p

# Write script to run openvpn and allow it through firewall on boot using the template .txt file
sed 's/LOCALIP/'$LOCALIP'/' </home/$USER/OpenVPN-Setup/firewall-openvpn-rules.txt >/etc/firewall-openvpn-rules.sh
sudo chmod 700 /etc/firewall-openvpn-rules.sh
sudo chown root /etc/firewall-openvpn-rules.sh
sed -i -e '$i \/etc/firewall-openvpn-rules.sh\n' /etc/rc.local
sed -i -e '$i \sudo service openvpn start\n' /etc/rc.local

# Write default file for client .ovpn profiles, to be used by the MakeOVPN script, using template .txt file
sed 's/PUBLICIP/'$PUBLICIP'/' </home/$USER/OpenVPN-Setup/Default.txt >/etc/openvpn/easy-rsa/keys/Default.txt

# Make directory under home directory for .ovpn profiles
mkdir /home/$USER/ovpns
chmod 777 -R /home/$USER/ovpns

# Make other scripts in the package executable
cd /home/$USER/OpenVPN-Setup
sudo chmod +x MakeOVPN.sh
sudo chmod +x remove.sh
chmod +x clean-ovpns.sh

whiptail --title "Setup OpenVPN" --msgbox "Configuration complete. Restart \
system to apply changes and start VPN server." 8 78
