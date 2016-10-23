publicIP=$(/usr/bin/curl -s http://whatismyip.akamai.com/)
enp1s8IP=$( /usr/sbin/ip addr show | /usr/bin/grep enp1s8 | /usr/bin/grep -o "inet [0-9]*\.[0-9]*\.[0-9]*\.[0-9]*" | /usr/bin/grep -o "[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*")
tun0IP=$( /usr/sbin/ip addr show | /usr/bin/grep tun0 | /usr/bin/grep -o "inet [0-9]*\.[0-9]*\.[0-9]*\.[0-9]*" | /usr/bin/grep -o "[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*")



USER="PIAuserHere"
PASSWORD="PIApassHere"


client_id1=$(/usr/bin/head -n 100 /dev/urandom | /usr/bin/md5sum | /usr/bin/tr -d " -")  
port1=$(/usr/bin/wget -q --post-data="user=$USER&pass=$PASSWORD&client_id=$client_id1&local_ip=$tun0IP" -O - 'https://www.privateinternetaccess.com/vpninfo/port_forward_assignment' | /usr/bin/head -1)
port1=$(echo $port1 | awk -F ':|}' '{print $2}')

echo $port1 >> /opt/ovr/port1.log
if [[ "$port1" == "\"Port forwarding not available for this region\"" ]]; then
    echo "Setting ssh to 22" >> /opt/ovr/port1.log
    port1="22"
else
    echo "Setting ssh to $port1" >> /opt/ovr/port1.log
fi





#configure sshd to listen to new forwarded port.
/usr/bin/sed -i '/Port /d' /etc/ssh/sshd_config
/usr/bin/echo "Port $port1" >> /etc/ssh/sshd_config
#/usr/sbin/semanage port -m -t ssh_port_t -p tcp $port1
/usr/bin/systemctl restart sshd


#define iptables absolute location:
iptables=/usr/sbin/iptables

#include new forwarded port through firewall.

if [[ ! "$port1" == "22" ]]; then
    $iptables -I INPUT -i enp1s8 -p tcp --dport $port1 -m state --state NEW,ESTABLISHED -j ACCEPT
    $iptables -I OUTPUT -o enp1s8 -p tcp --sport $port1 -m state --state ESTABLISHED -j ACCEPT
fi
$iptables -I INPUT -i enp1s1 -p tcp --dport $port1 -m state --state NEW,ESTABLISHED -j ACCEPT
$iptables -I OUTPUT -o enp1s1 -p tcp --sport $port1 -m state --state ESTABLISHED -j ACCEPT
service iptables save

#Forward web server's port 80.
client_id2=$(/usr/bin/head -n 100 /dev/urandom | /usr/bin/md5sum | /usr/bin/tr -d " -")  
port2=$(/usr/bin/wget -q --post-data="user=$USER&pass=$PASSWORD&client_id=$client_id2&local_ip=$tun0IP" -O - 'https://www.privateinternetaccess.com/vpninfo/port_forward_assignment' | /usr/bin/head -1)
port2=$(echo $port2 | awk -F ':|}' '{print $2}')

internalAddress=10.0.0.13
internalPort=80
if [[ ! "$port2" == "\"Port forwarding not available for this region\"" ]]; then
    $iptables -I PREROUTING -t nat -i tun0 -p tcp --dport $port2 -j DNAT --to $internalAddress:$internalPort
    $iptables -I PREROUTING -t nat -i enp1s8 -p tcp --dport $port2 -j DNAT --to $internalAddress:$internalPort
    $iptables -I FORWARD -p tcp -d webServer --dport $port2 -j ACCEPT
    service iptables save
fi


message="enp1s8IP=$enp1s8IP\n\nssh -l root -o \"Port=$port1\" $publicIP\n\n$publicIP:$port2/video\n\nBe a rock star today."

echo -e "$message" | /usr/bin/mail -s "IP Update" "wayne.workman2012@gmail.com"


