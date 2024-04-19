#!/bin/bash

# Function to check if LXC is installed
check_lxc_installed() {
    if ! command -v lxc &> /dev/null; then
        echo "LXC could not be found."
        exit 1
    fi
}

#Function to create configuration
generate_config() {

    echo ""
    echo "-- No config file was found. Starting configuration (press Ctrl-C for cancle)"
    echo ""
    read -e -p "Enter the OS image name to be used for new containers: " IMAGE_NAME
    read -e -p "Standard username for sudo and ssh: " STANDARD_USER
    mkdir ~/.lxc-container-setup
    echo "image: $IMAGE_NAME;" > ~/.lxc-container-setup/lxc-container.conf
    echo "standard_user: $STANDARD_USER;" >> ~/.lxc-container-setup/lxc-container.conf
    echo "config generated"
    echo ""
}


#Reading the config file
read_config() {

    while read y
    do
    if [[ "$y" == *"image"* ]]
    then IMAGE_NAME=$(awk '{ sub(/.*image: /, ""); sub(/;.*/, ""); print }' <<< "$y")
    elif [[ "$y" == *"standard_user"* ]]
    then STANDARD_USER=$(awk '{ sub(/.*standard_user: /, ""); sub(/;.*/, ""); print  }' <<< "$y")
    else echo "no server found: $y"
    fi
    done < ~/.lxc-container-setup/lxc-container.conf
}


# Function to create a new container
create_container() {
    echo "-- Creating new container based on $IMAGE_NAME named $1..."
    echo ""
    lxc launch $IMAGE_NAME $1
}

# Function to configure SSH access
configure_ssh() {
    echo ""
    echo "-- Configuring user $STANDARD_USER for sudo and SSH access..."
    echo ""
    lxc exec $1 -- adduser $STANDARD_USER
    lxc exec $1 -- usermod -aG sudo $STANDARD_USER
    echo ""
    echo "-- Installing and configuring SSH server"
    echo ""
    lxc exec $1 -- apt-get update
    lxc exec $1 -- apt-get install -y openssh-server
    lxc exec $1 -- sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
    echo ""
    echo "-- Copy ssh public keys"
    echo ""
    lxc exec $1 -- mkdir /home/$STANDARD_USER/.ssh
    lxc exec $1 -- chmod 700 /home/$STANDARD_USER/.ssh
    lxc file push ~/.ssh/authorized_keys $1/home/$STANDARD_USER/.ssh/authorized_keys
    lxc exec $1 -- chmod 600 /home/$STANDARD_USER/.ssh/authorized_keys
    lxc exec $1 -- chown $STANDARD_USER:$STANDARD_USER -R /home/$STANDARD_USER/.ssh
    lxc exec $1 -- systemctl restart ssh
}


# Function to install UrBackup client
install_urbackup_client() {
    
    echo ""
    echo "-- Installing UrBackup client..."
    echo ""
    lxc exec $1 -- sh -c 'TF=`mktemp` && wget "https://hndl.urbackup.org/Client/2.5.25/UrBackup%20Client%20Linux%202.5.25.sh" -O $TF && sudo sh $TF; rm -f $TF'
    echo "-- Adding /etc as Backupdir"
    echo ""
    lxc exec $1 -- urbackupclientctl add-backupdir -d /etc
}


#Function to install basic tools
install_basic_tools() {
    echo ""
    echo "-- Installing basic tools.."
    echo ""
    lxc exec $1 -- apt install mc

}


# Main script


# Testing if there is a config file available.
if test -f ~/.lxc-container-setup/lxc-container.conf
then
# Reading config
    echo -e "~/.lxc-container-setup/lxc-container.conf found"
    echo ""
    read_config

check_lxc_installed

read -p "Enter the name of the container: " container_name

create_container $container_name
configure_ssh $container_name
read -p "Install Urbackup Client? (y/n): " yn
if [[ "$yn" = "y" ]]
 then install_urbackup_client $container_name
fi
install_basic_tools $container_name

echo ""
echo -e "-- Setup complete for container $container_name."
echo ""
lxc list | grep $container_name
echo ""

# If no config available, start configuration function
else
    generate_config
fi


