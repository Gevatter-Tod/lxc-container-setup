
A simple shell script to launch new containers and configure the basic settings

**What it does**
- Defines one time standard settings: lxc container base image and standard username
- Ask for a container name and launch the container
- Install openssh and copy ssh key files
- Install Urbackupclient and some other basic tools (currently only mc)

**Installation**
Download the "new-lxc-container-setup.sh" file and make it executable on you lxc host mashine

Your Settings are stored in "~/.lxc-container-setup/lxc-container.conf"