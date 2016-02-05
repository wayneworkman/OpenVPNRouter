iptables --policy INPUT ACCEPT
iptables --policy OUTPUT ACCEPT
iptables --policy FORWARD ACCEPT
iptables -t nat -F
iptables -t nat -X
iptables -Z
iptables -F
iptables -X
iptables -t mangle -F
iptables -t mangle -X
ip link delete tun0
kill -9 $( pgrep openvpn )
kill -9 $( pgrep openvpn )
service iptables save
service iptables restart
