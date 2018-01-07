# SELinux prevents this from running under CRON


#-----------------------------Load settings.

#Set working directory.
DIR=/opt/ovr

site=8.8.8.8

speed=5


#Send bars for seperation in log.

$echo "##########" >> $DIR/ovr.log



#Write log entry to self-heal.log
dt="$( $date  +"%I:%M %p %m-%d-%Y")"


#Get tun0's IP.
tun0IP="$( $ip addr show | $grep tun0 | $grep -o "inet [0-9]*\.[0-9]*\.[0-9]*\.[0-9]*" | $grep -o "[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*")"

#Device used for the VPN Tunnel.
#CentOS7
device="/proc/net/dev_snmp6/tun0"

$echo Testing $device with IP $tun0IP for existence and connectivity at $dt >> $DIR/ovr.log

if [ -f $device ]; then

	$ping -c 1 $site -I tun0


	if [[ $? -eq 0 ]]; then
		$echo "Tunnel is online." >> $DIR/ovr.log
		result=0
	else
		$echo "Tunnel exists but is not online." >> $DIR/ovr.log
		result=1	
	fi
else
	$echo "Tunnel does not exist." >> $DIR/ovr.log
	result=2
fi



if [[ $result == 0 ]]; then
	#nothing, all is good.
	echo "Ok!" > /dev/null 2>&1
else

	$echo Attempting to fix... >> $DIR/ovr.log
	$echo " " >> $DIR/ovr.log
    
	$echo "Resetting..." >> $DIR/ovr.log
	$iptables --policy INPUT ACCEPT
	$iptables --policy OUTPUT ACCEPT
	$iptables --policy FORWARD ACCEPT
	$iptables -t nat -F
	$iptables -t nat -X
	$iptables -Z
	$iptables -F
	$iptables -X
	$iptables -t mangle -F
	$iptables -t mangle -X
	$ip link delete tun0
	kill -9 $( pgrep openvpn )
	kill -9 $( pgrep openvpn )



	#give the above commands a moment.
	sleep 4
    
	$echo " " >> $DIR/ovr.log
	$echo "Getting the tunnel re-established..." >> $DIR/ovr.log
	$openvpn --config $DIR/custom.ovpn --daemon >> $DIR/ovr.log
	$echo "Sleeping for 20 seconds..." >> $DIR/ovr.log
	sleep 10


	$echo " " >> $DIR/ovr.log
	$echo "Get the tunnels new IP..." >> $DIR/ovr.log
	tun0IP="$( $ip addr show | $grep tun0 | $grep -o "inet [0-9]*\.[0-9]*\.[0-9]*\.[0-9]*" | $grep -o "[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*")"
	
	$echo tun0 IP is now: $tun0IP >> $DIR/ovr.log

	$echo " " >> $DIR/ovr.log
	
	$DIR/./setiptables.sh


	#$wget -q --tries $speed --timeout $speed --spider $site --bind-address $tun0IP
	$ping -c 1 $site -I tun0


	if [[ $? -eq 0 ]]; then
		$echo " " >> $DIR/ovr.log
		$echo "Tun0 is now online, saving rules!" >> $DIR/ovr.log
		service iptables save >> $DIR/ovr.log
		$echo $tun0IP > $DIR/oldIP.txt
	else
		numberOfFailures=0
		$echo Failed to fix. >> $DIR/ovr.log
		if [[ -e $DIR/numberOfFailures.txt ]]; then
			numberOfFailures=$( $echo $DIR/numberOfFailures.txt )
		fi
		let numberOfFailures+=1
		if [[ $numberOfFailures -ge $failuresBeforeReboot ]]; then
			if [[ -e $DIR/numberOfFailures.txt ]]; then
				rm -f $DIR/numberOfFailures.txt
			fi
			$echo "Reboot at: $dt" >> $DIR/reboot.log
			$reboot
		else
			echo $numberOfFailures > $DIR/numberOfFailures
		fi
	fi
fi

