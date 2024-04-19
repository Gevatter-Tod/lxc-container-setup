#!/bin/bash

# Function to check if LXC is installed
check_lxc_installed() {
    if ! command -v lxc &> /dev/null; then
        echo "LXC could not be found. Please install LXC first."
        exit 1
    fi
}

# Function to create a new container
create_container() {
    echo "Creating a new Ubuntu container named $1..."
    lxc launch rose-ubuntu2204 $1
}

# Function to configure SSH access
configure_ssh() {
    echo "Configuring sudo user and SSH access..."
    read -e -p "Enter the name of the sudo user: " user_name
    lxc exec $1 -- adduser $user_name
    lxc exec $1 -- usermod -aG sudo $user_name
    echo "Installing and configuring SSH server"
    lxc exec $1 -- apt-get update
    lxc exec $1 -- apt-get install -y openssh-server
    lxc exec $1 -- sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
    echo "Copy ssh public keys"
    lxc exec $1 -- mkdir /home/$user_name/.ssh
    lxc exec $1 -- chmod 700 /home/$user_name/.ssh
    lxc file push ~/.ssh/authorized_keys $1/home/$user_name/.ssh/authorized_keys
    lxc exec $1 -- chmod 600 /home/$user_name/.ssh/authorized_keys
    lxc exec $1 -- chown $user_name:$user_name -R /home/$user_name/.ssh
    lxc exec $1 -- systemctl restart ssh
}


# Function to install UrBackup client
install_urbackup_client() {
    echo "Installing UrBackup client..."
    lxc exec $1 -- sh -c 'TF=`mktemp` && wget "https://hndl.urbackup.org/Client/2.5.25/UrBackup%20Client%20Linux%202.5.25.sh" -O $TF && sudo sh $TF; rm -f $TF'
    echo "Adding /etc as Backupdir"
    lxc exec $1 -- urbackupclientctl add-backupdir -d /etc
}


#Function to install basic tools
install_basic_tools() {
    echo "Installing basic tools.."
    lxc exec $1 -- apt install mc

}


# Main script
check_lxc_installed

read -p "Enter the name of the container: " container_name

create_container $container_name
configure_ssh $container_name
install_urbackup_client $container_name
install_basic_tools $container_name

echo "Setup complete for container $container_name."
lxc list | grep $container_name



