crontab -l -u root | grep -v selfheal.sh | crontab -u root -
rm -rf /opt/ovr
/sbin/iptables --policy INPUT ACCEPT
/sbin/iptables --policy OUTPUT ACCEPT
/sbin/iptables --policy FORWARD ACCEPT
/sbin/iptables -t nat -F
/sbin/iptables -t nat -X
/sbin/iptables -Z
/sbin/iptables -F
/sbin/iptables -X
/sbin/iptables -t mangle -F
/sbin/iptables -t mangle -X
/sbin/ip link delete tun0
echo 0 > /proc/sys/net/ipv4/ip_forward
