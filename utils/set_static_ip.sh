#nmcli con show
#first arg username, second arg ip (or <hostname>.local)
# -o StrictHostKeyChecking=no is not necessary assuming this script is called with <hostname>.local and run from the workstation used to manually SSH (via mDNS) and remove sudo password requirement
echo "--- may take a few minutes if mDNS resolution is slow ---"
ssh $1@$2 'sudo nmcli con mod "Wired connection 1" ipv4.addresses 192.168.50.1/24 && sudo nmcli con mod "Wired connection 1" ipv4.method manual && sudo nmcli con up "Wired connection 1"'
