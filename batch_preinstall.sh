#first arg is username, second arg is number of machines
#hostnames must conform to 'raspberrypi-i' format where i=1,2,3,... 
set -e
for ((i=1; i<=$2; i++)); do
    #./utils/set_static_ip.sh $1 raspberrypi-$i.local #uncomment for headless install. sets static ips to 192.168.50.1,2,3,...
    ./utils/transfer.sh $1 192.168.50.$i #transfer.sh takes care of ssh hostname conflict if connecting with a different IP than before (for headless install)
    ssh $1@192.168.50.$i "sudo /home/$1/Downloads/preinstall.sh"
done
