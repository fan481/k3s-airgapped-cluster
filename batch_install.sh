#first arg is username, second arg is number of machines
#script sets .1 ip assigned server as the control plane
set -e
./sync_time.sh #sync time, needed for k8s TLS certificates to work (can comment out if install is not airgapped and RPis automatically updated time/date)
ssh $1@192.168.50.1 "sudo INSTALL_K3S_SKIP_DOWNLOAD=true /home/$1/Downloads/install.sh"
TOKEN = $(ssh $1@192.168.50.1 "sudo cat /var/lib/rancher/k3s/server/agent-token") #may fail if the ssh mount in this command cannot access the directory,
#echo "$TOKEN"
for ((i=2; i<=$2; i++)); do
    ssh $1@192.168.50.$i "sudo INSTALL_K3S_SKIP_DOWNLOAD=true K3S_URL=https://192.168.50.1:6443 K3S_TOKEN='$TOKEN' /home/$1/Downloads/install.sh"
done