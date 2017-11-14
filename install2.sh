if (whiptail --title "Setup OpenVPN" --yesno "You are about to configure your \
Raspberry Pi as a VPN server running OpenVPN. Are you sure you want to \
continue?" 8 78) then
 whiptail --title "Setup OpenVPN" --infobox "OpenVPN will be installed and \
 configured." 8 78
else
 whiptail --title "Setup OpenVPN" --msgbox "Cancelled" 8 78
 exit
fi

# Install openvpn
echo "Installing openvpn"
apt-get -y install openvpn

# Install and prepare Easy RSA
#change to download from Github
apt-get install easy-


# Copy the easy-rsa files to a directory inside the new openvpn directory
cp -r /etc/EasyRSA-3.0.3 /etc/openvpn
#cp -r /usr/share/easy-rsa /etc/openvpn

# Edit the EASY_RSA variable in the vars file to point to the new easy-rsa directory,
# And change from default 1024 encryption if desired
cd /etc/openvpn/EasyRSA-3.0.3
#cd /etc/openvpn/easy-rsa
cp vars.example vars
sed -i 's:"$PWD":"/etc/openvpn/easy-rsa":' vars
if [ $ENCRYPT = 1024 ]; then
 sed -i 's:KEY_SIZE=2048:KEY_SIZE=1024:' vars
fi

# source the vars file just edited
source ./vars
