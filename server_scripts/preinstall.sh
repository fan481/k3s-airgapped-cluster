#!/bin/bash
#MUST RUN WITH SUDO
#prep k3s install files
echo "--- setup k3s install files, should not take very long ---"
mkdir -p /var/lib/rancher/k3s/agent/images/
cp /home/$USER/Downloads/k3s-airgap-images-arm64.tar /var/lib/rancher/k3s/agent/images/k3s-airgap-images-arm64.tar
cp /home/$USER/Downloads/k3s-arm64 /usr/local/bin/k3s #rename as k3s
chmod +x /usr/local/bin/k3s
#setup default route: during boot, NetworkManager should run the route setup script in pre-up.d
echo "--- copy/enable route setup script to NetworkManager pre-up.d, should not take very long ---"
cp /home/$USER/Downloads/k3s-route-setup.sh /etc/NetworkManager/dispatcher.d/pre-up.d/k3s-route-setup.sh
chmod +x /etc/NetworkManager/dispatcher.d/pre-up.d/k3s-route-setup.sh
#enable cgroups, required for k3s to start the systemd service
echo "--- add boot option: cgroups (enable memory control) ---"
sed -i '$s/$/ cgroup_enable=memory cgroup_memory=1/' /boot/firmware/cmdline.txt
#echo "--- change hostname and cleanup /etc/hosts ---"
#hostnamectl set-hostname $1
#sed -i "s/raspberrypi/$1/g" /etc/hosts 2>/dev/null #will give ignorable error that this command fixes
#reboot
echo "--- rebooting ---"
shutdown -r now