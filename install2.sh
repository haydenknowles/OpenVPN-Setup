if (whiptail --title "Setup OpenVPN" --yesno "You are about to configure your \
Raspberry Pi as a VPN server running OpenVPN. Are you sure you want to \
continue?" 8 78) then
 whiptail --title "Setup OpenVPN" --infobox "OpenVPN will be installed and \
 configured." 8 78
else
 whiptail --title "Setup OpenVPN" --msgbox "Cancelled" 8 78
 exit
fi

#Step 4A Install openvpn
echo "Installing openvpn"
apt-get -y install openvpn

#Step 4B Install and prepare Easy RSA
VER=2 # Easy-RSA version number
cd /etc/openvpn
mkdir easy-rsa
wget https://github.com/OpenVPN/easy-rsa/archive/release/$VER.x.zip
unzip $VER.x.zip
rm $VER.x.zip

# Step 5 Copy the easy-rsa files to a directory inside the new openvpn directory
cp -r /etc/openvpn/easy-rsa-release-$VER.x/easy-rsa/2.0/* /etc/openvpn/easy-rsa

#Step 6 Go to new easy-rsa directory
cd /etc/openvpn/easy-rsa

#Step 7 Edit vars
#Edit the EASY_RSA variable in the vars file to point to the new easy-rsa directory,
#And change from default 1024 encryption if desired
cp vars vars.backup
sed -i 's:"`pwd`":"/etc/openvpn/easy-rsa":' vars #
if [ $ENCRYPT = 1024 ]; then
 sed -i 's:KEY_SIZE=2048:KEY_SIZE=1024:' vars #
fi

#Step 8 Source vars file and build the CA
source ./vars
./clean-all
./build-ca

#Step 9 Build server key pair
./build-key-server server

#Step 12 Generate Diffie-Hellman exchange
./build-dh

#Step 13 Generate HMAC key
openvpn --genkey --secret keys/ta.key

#Step 14 Edit server.conf