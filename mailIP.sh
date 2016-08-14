publicIP=$(/usr/bin/curl -s http://whatismyip.akamai.com/)
tun0IP=$( /usr/sbin/ip addr show | /usr/bin/grep tun0 | /usr/bin/grep -o "inet [0-9]*\.[0-9]*\.[0-9]*\.[0-9]*" | /usr/bin/grep -o "[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*")
enp1s8IP=$( /usr/sbin/ip addr show | /usr/bin/grep enp1s8 | /usr/bin/grep -o "inet [0-9]*\.[0-9]*\.[0-9]*\.[0-9]*" | /usr/bin/grep -o "[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*")

USER="TheUser"
PASSWORD="ThePassword"

local_ip=$( /usr/sbin/ip addr show | /usr/bin/grep tun0 | /usr/bin/grep -o "inet [0-9]*\.[0-9]*\.[0-9]*\.[0-9]*" | /usr/bin/grep -o "[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*")
client_id=$(/usr/bin/head -n 100 /dev/urandom | /usr/bin/md5sum | /usr/bin/tr -d " -")  
port=$(/usr/bin/wget -q --post-data="user=$USER&pass=$PASSWORD&client_id=$client_id&local_ip=$local_ip" -O - 'https://www.privateinternetaccess.com/vpninfo/port_forward_assignment' | /usr/bin/head -1)
port=$(echo $port | awk -F ':|}' '{print $2}')

#configure sshd to listen to new forwarded port.
/usr/bin/sed -i '/Port /d' /etc/ssh/sshd_config
/usr/bin/echo "Port $port" >> /etc/ssh/sshd_config
systemctl restart sshd


#include new forwarded port through firewall.
iptables=/usr/sbin/iptables
$iptables -I INPUT -i enp1s8 -p tcp --dport $port -m state --state NEW,ESTABLISHED -j ACCEPT
$iptables -I OUTPUT -o enp1s8 -p tcp --sport $port -m state --state ESTABLISHED -j ACCEPT
service iptables save



message="Public IP\n$publicIP\n\ntun0 IP\n$tun0IP\n\nenp1s8 IP\n$enp1s8IP\n\nPort\n$port"

echo -e "$message" | /usr/bin/mail -s "IP Update" wayne.workman2012@gmail.com
