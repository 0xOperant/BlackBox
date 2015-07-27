# BlackBox
Raspbian + openVPN wifi travel router

##Server Setup

### launch_AMI.sh
launches a new AWS EC2 instance with the options provided, then calls configure_VPN.sh

### configure_VPN.sh
called by launch_AMI.sh, installs packages and configures the system as an OpenVPN server

### Notes
1. You must already have an AWS account, and the EC2 CLI Tools configured on your system (https://aws.amazon.com/cli/).
2. Once the setup is complete, you must scp your public/private key pair (generated offline) to the /etc/openvpn/ directory.
3. You must have an API key from pushover.net to enable push notifications.

Acknowledgements:
I borrowed heavily from https://github.com/sebsto/AWSVPN

##Client Setup
Work in progress...sorry.

