#first arg username, second arg number of machines
DT='2026-06-20 14:30:00'
for ((i=1; i<=$2; i++)); do
    echo "---setting time for $1@192.168.50.$i to $DT---"
    ssh $1@192.168.50.$i "sudo timedatectl set-ntp false && sudo timedatectl set-time '$DT' && sudo timedatectl set-ntp true"
done