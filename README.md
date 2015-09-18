# BlackBox
Raspbian + openVPN wifi travel router

## Server Setup

### launch_AMI.sh
Launches a new AWS EC2 instance with the options provided, then calls configure_VPN.sh

### configure_VPN.sh
Called by launch_AMI.sh, installs packages and configures the system as an OpenVPN server

### migrate_AMI.sh
Creates a new instance with configure_VPN.sh, migrates the existing Elastic IP from the old instance to the new instance, then terminates the old instance. Use with care.

### Notes
1. You must already have an AWS account, and the AWS CLI Tools configured on your system (http://docs.aws.amazon.com/cli/latest/index.html) for launch_AMI.sh to work.
2. Once the setup is complete, you must scp your CA certificate (ca.crt) and public/private key pair (vpnserver.crt, vpnserver.key, generated offline) to the /etc/openvpn/ directory, and then download the TLS key (ta.key) to your client.
3. You must have an API key from pushover.net to enable push notifications.
4. The configure_VPN.sh script "should" work on any Ubuntu 14.04 system, including a new droplet/linode/etc. Just login and run the script as root.
5. The launch_AMI.sh script will output a log file to your current directory containing instance details, including it's public IP address. You will need this in order to setup a DNS A record with your DNS provider. I want to script this as well.
6. I have sacrificed speed for security with my VPN settings. Not sorry. Throughput is still quite good, even in most hotels.
7. If you have an afternoon to waste, this guide (https://github.com/belldavidr/BlackBox/wiki/BlackBox-Server-Setup) will walk you through manually setting up the BlackBox server.  Or, just run the 4-minute script.

Acknowledgements:
I borrowed heavily from https://github.com/sebsto/AWSVPN

## Client Setup
Work in progress...sorry. Here are the basic ([HW/SW requirements])(https://github.com/belldavidr/BlackBox/wiki/BlackBox-Client-Setup).

I plan to adapt the configure_VPN script for configuring the Raspbian client. I will let you know how it turns out.

