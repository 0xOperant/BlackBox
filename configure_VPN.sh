#!/bin/sh

#provide pushover.net credentials (optional)
#TOKEN= #Your token
#USER= #Your user key

#ensure kernel and packages are up-to-date
apt-get update && apt-get upgrade -y
apt-get dist-upgrade -y
apt-get autoremove -y

#install fail2ban
apt-get install fail2ban -y

#change fail2ban bantime from default 10mins to 60mins
sed '0,/600/s/600/3600/' /etc/fail2ban/jail.conf > /etc/fail2ban/jail.conf.out
rm /etc/fail2ban/jail.conf
cp /etc/fail2ban/jail.conf.out /etc/fail2ban/jail.conf 
rm /etc/fail2ban/jail.conf.out
service fail2ban restart

#disable IPv6
echo net.ipv6.conf.all.disable_ipv6 = 1 >> /etc/sysctl.conf
echo net.ipv6.conf.default.disable_ipv6 = 1 >> /etc/sysctl.conf
echo net.ipv6.conf.lo.disable_ipv6 = 1 >> /etc/sysctl.conf
cat /proc/sys/net/ipv6/conf/all/disable_ipv6

#restrict SSH access to IPv4, disable root login, then restart SSH service.
sed -i 's/#ListenAddress 0.0.0.0/ListenAddress 0.0.0.0/g' /etc/ssh/sshd_config
sed -i 's/ListenAddress ::/#ListenAddress ::/g' /etc/ssh/sshd_config
sed -i 's/PermitRootLogin without-password/PermitRootLogin no/g' /etc/ssh/sshd_config
service ssh restart

#configure iptables to allow established sessions, SSH (tcp 22), openVPN (udp 1194), and drop all other traffic
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p udp --dport 1194 -j ACCEPT
iptables -A INPUT -j DROP

#route VPN traffic to Internet
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE

#save IPv4 iptables
mkdir /etc/iptables
iptables-save > /etc/iptables/rules.v4

#enable IPv4 routing
echo 1 > /proc/sys/net/ipv4/ip_forward

#ensure iptables and IPv4 routing persist reboots
cat > /etc/network/if-pre-up.d/iptablesload <<EOF
#!/bin/sh
iptables-restore < /etc/iptables/rules.v4
echo 1 > /proc/sys/net/ipv4/ip_forward
exit 0
EOF
chmod +x /etc/network/if-pre-up.d/iptablesload

#edit rc.local to execute iptablesload at startup
cat > /etc/rc.local <<EOF
#load iptables and enable IPv4 routing
/etc/network/if-pre-up.d/iptablesload
exit 0
EOF

#ALL VPN CERTIFICATES WILL BE GENERATED OFFLINE AND MOVED VIA SCP.  DO NOT INSTALL EASY-RSA OR CREATE CA ON THIS SERVER.

#Ubuntu openVPN packages are old and missing important security requirements. Add openVPN repo, then download and install openVPN.
wget -O - https://swupdate.openvpn.net/repos/repo-public.gpg|apt-key add -
echo "deb http://swupdate.openvpn.net/apt trusty main" > /etc/apt/sources.list.d/swupdate.openvpn.net.list
apt-get update && apt-get install openvpn -y

#Generate Diffie-Hellman parameters
/usr/bin/openssl dhparam -out /etc/openvpn/dh2048.pem 2048

#Generate TLS shared secret. This must be kept secret and transferred to client via SCP.
/usr/sbin/openvpn --genkey --secret /etc/openvpn/ta.key

#Configure openVPN server. After keys have been uploaded, edit this file to reflect.
#OpenVPN will not start until required files are in place.
cat > /etc/openvpn/server.conf <<EOF
port 1194
proto udp
dev tun
ca /etc/openvpn/ca.crt
cert /etc/openvpn/vpnserver.crt
key /etc/openvpn/vpnserver.key
dh /etc/openvpn/dh2048.pem
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist /etc/openvpn/ipp.txt
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 208.67.222.222"
push "dhcp-option DNS 208.67.220.220"
push "dhcp-option DNS 8.8.8.8"
keepalive 10 120
tls-auth /etc/openvpn/ta.key 0
tls-version-min 1.2
remote-cert-tls client
cipher AES-256-CBC
auth SHA512
comp-lzo
max-clients 5
user nobody
group nogroup
persist-key
persist-tun
status /etc/openvpn/openvpn-status.log
log-append /etc/openvpn/openvpn.log
verb 3
script-security 2
client-connect /etc/openvpn/clientalert.sh
EOF

#OPTIONAL: Add clientalert.sh to enable push alerts upon client connection.
cat > /etc/openvpn/clientalert.sh <<EOF
#!/bin/bash
#Send push alert via pushover.net when clients connect
NOW="\$(date +"%H:%M:%S on %m-%d-%Y")"

curl -s \\
  --form-string "token=$TOKEN" \\
  --form-string "user=$USER" \\
  --form-string "sound=incoming" \\
  --form-string "message=At \$NOW, \$common_name connected to your AWS OpenVPN Server from public IP \$untrusted_ip" \\
https://api.pushover.net/1/messages.json

exit 0
EOF

#make clientalert.sh executable
chmod +x /etc/openvpn/clientalert.sh
