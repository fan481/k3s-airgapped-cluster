#first arg username, second arg ip
echo "--- mkdir /home/$1/Downloads ---"
ssh -o StrictHostKeyChecking=no $1@$2 mkdir /home/$1/Downloads #use -o StrictHostKeyChecking=no to avoid issues with sshing to host through different IP
echo "--- transferring files ---"
scp ../resources/k3s-arm64 $1@$2:/home/$1/Downloads
scp ../resources/k3s-airgap-images-arm64.tar $1@$2:/home/$1/Downloads
scp ../server_scripts/install.sh $1@$2:/home/$1/Downloads
scp ../server_scripts/preinstall.sh $1@$2:/home/$1/Downloads
scp ../server_scripts/k3s-route-setup.sh $1@$2:/home/$1/Downloads