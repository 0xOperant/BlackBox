# BlackBox
Raspbian + openVPN wifi travel router

### launch_AMI.sh
launches a new AWS EC2 instance with the options provided, then calls configure_VPN.sh

### configure_VPN.sh
called by launch_AMI.sh, installs packages and configures the system as an OpenVPN server

### Note
Once the setup is complete, you must scp your public/private key pair (generated offline) to the /etc/openvpn/ directory.
