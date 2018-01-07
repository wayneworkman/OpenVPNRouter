
displayMenus() {


	clear
	echo " "
	echo "   ____               __      _______  _   _ _____             _            ";
	echo "  / __ \              \ \    / /  __ \| \ | |  __ \           | |           ";
	echo " | |  | |_ __   ___ _ _\ \  / /| |__) |  \| | |__) |___  _   _| |_ ___ _ __ ";
	echo " | |  | | '_ \ / _ \ '_ \ \/ / |  ___/| . \` |  _  // _ \| | | | __/ _ \ '__|";
	echo " | |__| | |_) |  __/ | | \  /  | |    | |\  | | \ \ (_) | |_| | ||  __/ |   ";
	echo "  \____/| .__/ \___|_| |_|\/   |_|    |_| \_|_|  \_\___/ \__,_|\__\___|_|   ";
	echo "        | |                                                                 ";
	echo "        |_|                                                                 ";
	echo " "
	echo " "

	MENU="

A simple and secure router for your business or home,
with OpenVPN functionality for common VPN Providers.

Take your privacy to the next level!

Choose your OS type:

1   Fedora 19, 20, 21, CentOS 7, RHEL 7
2   Fedora 22, 23, and newer

"

	echo "$MENU"
  	echo -n "Selection: "
	read OS # Assign user input to variable


	if [[ -z $OS || ( $OS != 1 && $OS != 2 ) ]]; then
		echo Selection for OS was not acceptable, exiting.
		exit
	fi
	MENU="

Choose your VPN Provider:

1   Private Internet Access
2   other

"

	echo "$MENU"
	echo -n "Selection: "
	read VPN # Assign user input to variable


	if [[ -z $VPN || ( $VPN != 1 && $VPN != 2 ) ]]; then
		echo Selection for VPN was not acceptable, exiting.
		exit
	fi
	#Get credentials for vpn

	if [[ $VPN == 1 ]]; then


		if ! [ -e $DIR/login.conf ]; then

			echo -n "Please provide your PIA Username: "
			read UserName
			echo -n "Please provide your PIA Password: "
			read Password

			echo $UserName > $DIR/login.conf
			echo $Password >> $DIR/login.conf
	
		else
			UserName=$( sed -n '1p' < $DIR/login.conf )
			Password=$( sed -n '2p' < $DIR/login.conf )
			echo The current Username is: $UserName
			echo The current Password is: $Password
			echo " "

			read -r -p "Do you want to use these? [Y/n] " response
		
			case $response in
			[yY][eE][sS]|[yY]) 
				#Do nothing
				;;
			*)
				rm -f $DIR/login.conf
				echo -n "Please provide your PIA Username: "
				read UserName
				echo -n "Please provide your PIA Password: "
				read Password

				echo $UserName > $DIR/login.conf
				echo $Password >> $DIR/login.conf
				;;
			esac
		fi
	fi
	MENU="

Choose your DNS Provider:

1   FreeDNS 37.235.1.174 & 37.235.1.177
2   OpenDNS 208.67.222.222 & 208.67.220.220
3   Google DNS 8.8.8.8 & 8.8.4.4
4   other

"

	echo "$MENU"
	echo -n "Selection: "
	read DNS # Assign user input to variable


	if [[ -z $DNS || ( $DNS != 1 && $DNS != 2 && $DNS != 3 && $DNS != 4 ) ]]; then
		echo Selection for DNS was not acceptable, exiting.
		exit
	fi
	if [[ $DNS == 1 ]]; then
		MasterDNS=37.235.1.174
		SlaveDNS=37.235.1.177
	elif [[ $DNS == 2 ]]; then
		MasterDNS=208.67.222.222
                SlaveDNS=208.67.220.220
	elif [[ $DNS == 3 ]]; then
		MasterDNS=8.8.8.8
		SlaveDNS=8.8.4.4
	else 
		echo -n "Enter in primary DNS address: "
		read MasterDNS
		echo -n "Enter in secondary DNS address: "
		read SlaveDNS
		if ! [[ -z $MasterDNS && -z $SlaveDNS ]]; then
			echo You have to provide a primary and secondary DNS address, exiting.
			exit
		fi
	fi


	echo " "
	echo -n "Would you like to run DHCP on this machine? [Y/n]:"
	read answer

	if [[ $answer == "Y" || $answer == "y" || $answer == "YES" || $answer == "yes" || $answer == "Yes" ]]; then
		doDHCP=1
	elif [[ $answer == "N" || $answer == "n" || $answer == "NO" || $answer == "no" || $answer == "No" ]]; then
		doDHCP=0
	else
		echo Selection for DHCP was not acceptable, exiting.
	fi



}

identifyInterfaces() {


	ip link show > $DIR/interfaces.txt

	interface1name="$(sed -n '3p' $DIR/interfaces.txt)"
	interface2name="$(sed -n '5p' $DIR/interfaces.txt)"

	rm -f $DIR/interfaces.txt

	echo $interface1name | cut -d \: -f2 | cut -c2- > $DIR/interface1name.txt
	echo $interface2name | cut -d \: -f2 | cut -c2- > $DIR/interface2name.txt
	
	interface1name="$(cat $DIR/interface1name.txt)"
	interface2name="$(cat $DIR/interface2name.txt)"

	rm -f $DIR/interface1name.txt
	rm -f $DIR/interface2name.txt

	interface1ip="$(/sbin/ip addr show | grep $interface1name | grep -o "inet [0-9]*\.[0-9]*\.[0-9]*\.[0-9]*" | grep -o "[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*")"
	interface2ip="$(/sbin/ip addr show | grep $interface2name | grep -o "inet [0-9]*\.[0-9]*\.[0-9]*\.[0-9]*" | grep -o "[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*")"

	if [[ -z $interface1ip ]]; then
		interface1ip=127.0.0.1
                interface1hasInternet=0
		internalName=$interface1name
		internalIP=$interface1ip
	else
		wget -q --tries=$speed --timeout=$speed --spider $site --bind-address $interface1ip
		if [[ $? -eq 0 ]]; then
			interface1hasInternet=1
			externalName=$interface1name
			externalIP=$interface1ip
		else
			interface1hasInternet=0
			internalName=$interface1name
			internalIP=$interface1ip
		fi
	fi

        if [[ -z $interface2ip ]]; then
		interface2ip=127.0.0.1
		interface2hasInternet=0
		internalName=$interface2name
		internalIP=$interface2ip
        else
		wget -q --tries=$speed --timeout=$speed --spider $site --bind-address $interface2ip

		if [[ $? -eq 0 ]]; then
			interface2hasInternet=1
			externalName=$interface2name
			externalIP=$interface2ip
		else
			interface2hasInternet=0
			internalName=$interface2name
			internalIP=$interface2ip
		fi
	fi

        echo "Interface1 name: $interface1name interface1 IP: $interface1ip has internet: $interface1hasInternet"
        echo "Interface2 name: $interface2name interface2 IP: $interface2ip has internet: $interface2hasInternet"
        
	#Only proceed if one interface has internet and the other does not.
	if [ $interface1hasInternet == 1 ] && [ $interface2hasInternet == 0 ]; then
		echo "interface $interface1name  has internet."
		continue=1

	elif [ $interface1hasInternet == 0 ] && [ $interface2hasInternet == 1 ]; then
		echo "interface $interface2name has internet."
		continue=1
	elif [ $interface1hasInternet == 1 ] && [ $interface2hasInternet == 1 ]; then

		echo " "
		echo " "
		MENU="
It was detected that both interfaces have an internet connection.
Hopefully this is because the internal interface on this system was previously configured with this tool.
Please choose which interface to use as the external interface.
    1	interface: $interface1name IP: $interface1ip
    2	interface: $interface2name IP: $interface2ip
"
		echo "$MENU"
        	echo -n "Selection: "
        	read interfaceChoice # Assign user input to variable

        	if [[ -z $interfaceChoice || ( $interfaceChoice != 1 && $interfaceChoice != 2 ) ]]; then
                	echo Selection for interface was not valid, exiting.
                	exit
        	fi
		
		if [[ $interfaceChoice == 1 ]]; then
			interface1hasInternet=1
                	externalName=$interface1name
                	externalIP=$interface1ip
                	interface2hasInternet=0
                	internalName=$interface2name
                	internalIP=$interface2ip
		elif [[ $interfaceChoice == 2 ]]; then
                        interface1hasInternet=0
                        externalName=$interface2name
                        externalIP=$interface2ip
                        interface2hasInternet=1
                        internalName=$interface1name
                        internalIP=$interface1ip
		fi

		continue=1

	else
            # this should only execute if neither interface has internet.

		continue=0
	fi

	return $continue
}

initiateServices() {


	if [[ $OS == 1 || $OS == 2 ]]; then

		systemctl stop firewalld
		systemctl disable firewalld
		systemctl mask firewalld
		systemctl enable iptables
		systemctl start iptables
		service iptables save
		if [[ $doDHCP == 1 ]]; then
			systemctl enable dhcpd
			systemctl start dhcpd
		elif [[ $doDHCP == 0 ]]; then
			systemctl disable dhcpd
                	systemctl stop dhcpd
		else
			echo 'Error, unknown DHCP options. Not making any DHCP changes.'
		fi

	fi
}
installPackages() {

	#------------------------------Install what's needed.

	if [[ $OS == 1 ]]; then 

		yum update -y
		yum install epel-release -y
		yum install openvpn -y
		yum update openvpn -y
		yum remove epel-release -y
		if [[ $doDHCP == 1 ]]; then
			yum install dhcp -y
		fi
		yum install iptables-services unzip bc wget -y

	elif [[ $OS == 2 ]]; then

		dnf update -y
		dnf install openvpn iptables-services unzip bc wget -y
		if [[ $doDHCP == 1 ]]; then
			dnf install dhcp -y
		fi

	fi
}
loadSettings() {


	crontabMade="$(grep 'crontabMade=' $DIR/ovrsettings.conf | awk -F'"' '{$0=$2}1')"

	externalName="$(grep 'externalName=' $DIR/ovrsettings.conf | awk -F'"' '{$0=$2}1')"

	externalIP="$(grep 'externalIP=' $DIR/ovrsettings.conf | awk -F'"' '{$0=$2}1')"

	internalName="$(grep 'internalName=' $DIR/ovrsettings.conf | awk -F'"' '{$0=$2}1')"

	internalIP="$(grep 'internalIP=' $DIR/ovrsettings.conf | awk -F'"' '{$0=$2}1')"

}
make_setiptables() {



	if [[ -e $DIR/setiptables.sh ]]; then
		rm -f $DIR/setiptables.sh
	fi


	touch $DIR/setiptables.sh

	echo '#!/bin/bash' > $DIR/setiptables.sh

	echo modprobe=$modprobe >> $DIR/setiptables.sh
	echo ip=$ip >> $DIR/setiptables.sh
	echo grep=$grep >> $DIR/setiptables.sh
	echo echo=$echo >> $DIR/setiptables.sh
	echo date=$date >> $DIR/setiptables.sh
	echo wget=$wget >> $DIR/setiptables.sh
	echo iptables=$iptables >> $DIR/setiptables.sh
	echo openvpn=$openvpn >> $DIR/setiptables.sh



	echo 'tun0IP="$( $ip addr show | $grep tun0 | $grep -o "inet [0-9]*\.[0-9]*\.[0-9]*\.[0-9]*" | $grep -o "[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*")"' >> $DIR/setiptables.sh
	echo '$modprobe' ipt_MASQUERADE >> $DIR/setiptables.sh
	echo '$echo 1 > /proc/sys/net/ipv4/ip_forward' >> $DIR/setiptables.sh

	echo " "

	echo '$iptables' -A INPUT -i ${externalName} -p tcp --dport 22 -j DROP >> $DIR/setiptables.sh
	echo '$iptables' -A OUTPUT -o ${externalName} -p tcp --sport 22 -j DROP >> $DIR/setiptables.sh

	echo '$iptables' -A INPUT -i ${internalName} -p tcp --dport 22 -m state --state NEW,ESTABLISHED -j ACCEPT >> $DIR/setiptables.sh
	echo '$iptables' -A OUTPUT -o ${internalName} -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT  >> $DIR/setiptables.sh

	echo '$iptables' -t nat -A POSTROUTING -o tun0 -j SNAT --to '$tun0IP' >> $DIR/setiptables.sh
	echo '$iptables' -A INPUT -i tun0 -m state --state ESTABLISHED,RELATED -j ACCEPT >> $DIR/setiptables.sh
	echo '$iptables' -A OUTPUT -o tun0 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT >> $DIR/setiptables.sh

	#This reroutes all DNS traffic to the primary dns set during installation, doesn't matter what devices have configured.
	echo '$iptables' -t nat -A PREROUTING -p tcp --dport 53 -j DNAT --to ${MasterDNS}:53 >> $DIR/setiptables.sh
	echo '$iptables' -t nat -A PREROUTING -p udp --dport 53 -j DNAT --to ${MasterDNS}:53 >> $DIR/setiptables.sh



	#Below two lines are for lockdown

	echo '$iptables' -A INPUT DROP >> $DIR/setiptables.sh
	echo '$iptables' -A FORWARD -i ${externalName} -o ${externalName} -j DROP >> $DIR/setiptables.sh
	echo " " >> $DIR/setiptables.sh
	chmod +x $DIR/setiptables.sh


}
configurePaths() {
#---- Set Command Paths ----#

#Store previous contents of IFS.
previousIFS=$IFS
IFS=:

  for p in $PATH; do
	
	#Get grep path
	if [[ -f $p/grep ]]; then
		grep=$p/grep
	fi

	#Get echo path
	if [[ -f $p/echo ]]; then
		echo=$p/echo
	fi
	
	#Get date path
        if [[ -f $p/date ]]; then
                date=$p/date
        fi

        #Get wget path
        if [[ -f $p/wget ]]; then
                wget=$p/wget
        fi

        #Get iptables path
        if [[ -f $p/iptables ]]; then
                iptables=$p/iptables
        fi

        #Get openvpn path
        if [[ -f $p/openvpn ]]; then
                openvpn=$p/openvpn
        fi

	#Get ip path
        if [[ -f $p/ip ]]; then
                ip=$p/ip
        fi
	
	#Get modprobe path
        if [[ -f $p/modprobe ]]; then
                modprobe=$p/modprobe
        fi	
	
	#Get reboot path
	if [[ -f $p/reboot ]]; then
		reboot=$p/reboot
	fi
	
	#Get ping path
	if [[ -f $p/ping ]]; then
		ping=$p/ping
	fi		
  done

#Restore previous contents of IFS
IFS=$previousIFS


#---- Store the command paths at top of self-heal script ----#

echo ping=$ping | cat - $DIR/selfheal.sh > $DIR/temp && mv $DIR/temp $DIR/selfheal.sh
echo reboot=$reboot | cat - $DIR/selfheal.sh > $DIR/temp && mv $DIR/temp $DIR/selfheal.sh
echo modprobe=$modprobe | cat - $DIR/selfheal.sh > $DIR/temp && mv $DIR/temp $DIR/selfheal.sh
echo ip=$ip | cat - $DIR/selfheal.sh > $DIR/temp && mv $DIR/temp $DIR/selfheal.sh
echo grep=$grep | cat - $DIR/selfheal.sh > $DIR/temp && mv $DIR/temp $DIR/selfheal.sh
echo echo=$echo | cat - $DIR/selfheal.sh > $DIR/temp && mv $DIR/temp $DIR/selfheal.sh
echo date=$date | cat - $DIR/selfheal.sh > $DIR/temp && mv $DIR/temp $DIR/selfheal.sh
echo wget=$wget| cat - $DIR/selfheal.sh > $DIR/temp && mv $DIR/temp $DIR/selfheal.sh
echo iptables=$iptables | cat - $DIR/selfheal.sh > $DIR/temp && mv $DIR/temp $DIR/selfheal.sh
echo openvpn=$openvpn | cat - $DIR/selfheal.sh > $DIR/temp && mv $DIR/temp $DIR/selfheal.sh
echo '#!/bin/bash' | cat - $DIR/selfheal.sh > $DIR/temp && mv $DIR/temp $DIR/selfheal.sh

#make the main script executable.
chmod +x $DIR/selfheal.sh

}
additionalSelfHealSettings() {


#this function MUST be called before the "configurePaths" function.
echo failuresBeforeReboot=$failuresBeforeReboot | cat - $DIR/selfheal.sh > $DIR/temp && mv $DIR/temp $DIR/selfheal.sh


}
pickSite() {


	if [[ $VPN == 1 ]]; then

		HOSTS="aus-melbourne.privateinternetaccess.com:aus.privateinternetaccess.com:brazil.privateinternetaccess.com:ca.privateinternetaccess.com:ca-toronto.privateinternetaccess.com:denmark.privateinternetaccess.com:france.privateinternetaccess.com:germany.privateinternetaccess.com:hk.privateinternetaccess.com:in.privateinternetaccess.com:ireland.privateinternetaccess.com:israel.privateinternetaccess.com:italy.privateinternetaccess.com:japan.privateinternetaccess.com:mexico.privateinternetaccess.com:nl.privateinternetaccess.com:nz.privateinternetaccess.com:no.privateinternetaccess.com:ro.privateinternetaccess.com:russia.privateinternetaccess.com:sg.privateinternetaccess.com:sweden.privateinternetaccess.com:swiss.privateinternetaccess.com:turkey.privateinternetaccess.com:uk-london.privateinternetaccess.com:uk-southampton.privateinternetaccess.com:us-california.privateinternetaccess.com:us-east.privateinternetaccess.com:us-florida.privateinternetaccess.com:us-midwest.privateinternetaccess.com:us-newyorkcity.privateinternetaccess.com:us-seattle.privateinternetaccess.com:us-siliconvalley.privateinternetaccess.com:us-texas.privateinternetaccess.com:us-west.privateinternetaccess.com"

	fi
	echo " "
	echo " "
	echo Testing for the lowest latency connection available for your selected VPN.
	echo This will only take a moment...
	echo " "

	Counter=0
	Fastest="999999.9"
	FastestServer=""
	FastestCount=""
	IFS=:

	for p in $HOSTS; do

	Current=$( ping -c 4 -f -q $p | grep avg | awk -F'/' '{print $5}' )

	if ! [[ $(echo "$Fastest>$Current" | bc) -eq 0 ]]; then

		FastestServer=$p
		Fastest=$Current
		FastestCount=$Counter

	fi

	echo $Counter. $Current --- $p
	let Counter+=1

	done


	echo " "
	echo " "
	echo "The fastest site is $FastestServer with an average latency of $Fastest milliseconds."
	echo " "
	echo "It is recommended to go with either the lowest latency site or the site closest to you."
	echo "Theoretically, selecting the closest site means your data will travel a shorter distance,"
	echo "meaning there are fewer places where your data can be intercepted and stored."
	echo "However, picking the site with the lowest latency should offer the best performance." 
	echo "Usually, the lowest latency site and the closest site are the same."
	echo "The choice is yours."
	echo " "

	printf "Pick the site you want [$FastestCount]: "
	read ChosenSite # Assign user input to variable.


	if [[ -z $ChosenSite ]]; then
		#If no input is given, assign the offered default.
		ChosenSite=$FastestCount
	fi


	Counter=0
	for p in $HOSTS; do

	if [[ $Counter == $ChosenSite ]]; then
		export ChosenSite=$p
		break
	fi

	let Counter+=1

	done

}
setupCron() {

		crontab -l -u root | grep -v selfheal.sh | crontab -u root -
		newline="* * * * * $DIR/selfheal.sh"
		(crontab -l -u root; echo "$newline") | crontab -
}


setupPIA() {

	#This is is specific to PIA.

	if [ ! -e $DIR/ca.crt ] || [ ! -e $DIR/crl.pem ]; then

        	if [ ! -d $DIR/openvpn ]; then
			mkdir $DIR/openvpn
		fi

		wget https://www.privateinternetaccess.com/openvpn/openvpn.zip -P $DIR/openvpn
		unzip $DIR/openvpn/openvpn.zip -d $DIR/openvpn
		rm -f $DIR/openvpn/openvpn.zip
		rm -f $DIR/openvpn/*.ovpn
		mv $DIR/openvpn/ca.rsa.2048.crt $DIR/ca.crt
		mv $DIR/openvpn/crl.rsa.2048.pem $DIR/crl.pem
		rm -rf $DIR/openvpn




		#---- get what site will be used. ----#
		
		pickSite
		


		echo client > $DIR/custom.ovpn
		echo dev tun0 >> $DIR/custom.ovpn
		echo proto udp >> $DIR/custom.ovpn
		echo remote $ChosenSite 1194 >> $DIR/custom.ovpn
		echo resolv-retry infinite >> $DIR/custom.ovpn
		echo nobind >> $DIR/custom.ovpn
		echo persist-key >> $DIR/custom.ovpn
		echo persist-tun >> $DIR/custom.ovpn
		echo ca $DIR/ca.crt >> $DIR/custom.ovpn
		echo tls-client >> $DIR/custom.ovpn
		echo remote-cert-tls server >> $DIR/custom.ovpn
		echo auth-user-pass >> $DIR/custom.ovpn
		echo comp-lzo >> $DIR/custom.ovpn
		echo verb 1 >> $DIR/custom.ovpn
		echo reneg-sec 0 >> $DIR/custom.ovpn
		echo crl-verify $DIR/crl.pem >> $DIR/custom.ovpn
		echo auth-user-pass $DIR/login.conf >> $DIR/custom.ovpn

	fi
}

setupInternalInterface() {

        #Red hat / Fedora 19 - 23 / CentOS 7
        internalConfig=/etc/sysconfig/network-scripts/ifcfg-$internalName

        if [[ -f $internalConfig ]]; then

                UUID="$(grep 'UUID=' $internalConfig | awk -F'"' '{$0=$2}1')"


		internalIP=$desiredInternalIP
		internalMask=$desiredInternalMask

                rm -f $internalConfig
                touch $internalConfig

                echo TYPE="Ethernet" > $internalConfig
                echo BOOTPROTO=none >> $internalConfig
                echo DEFROUTE="yes" >> $internalConfig
                echo IPV4_FAILURE_FATAL="no" >> $internalConfig
                echo IPV6INIT="no" > $internalConfig
                echo IPV6_AUTOCONF="no" >> $internalConfig
                echo IPV6_FAILURE_FATAL="no" >> $internalConfig
                echo NAME="$internalName" >> $internalConfig
                echo UUID="$UUID" >> $internalConfig
                echo DEVICE="$internalName" >> $internalConfig
                echo ONBOOT="yes" >> $internalConfig
                echo PEERDNS="yes" >> $internalConfig
                echo DNS1=$MasterDNS >> $internalConfig
                echo DNS2=$SlaveDNS >> $internalConfig
                echo IPADDR=$internalIP >> $internalConfig
                echo PREFIX=$internalMask >> $internalConfig
                echo GATEWAY=$externalIP >> $internalConfig
                continue=1

        else

                echo The internal interface does not have a configuration file here:
                echo $internalConfig
                continue=0
        fi

        if [[ $continue == 1 ]]; then
                ifdown $internalName & wait
                ifup $internalName & wait  
        fi

        return $continue

}

cidr2mask() {
        #Expects CIDR notation (a single integer between 0 and 32)
        local i=""
        local mask=""
        local full_octets=$(($1/8))
        local partial_octet=$(($1%8))
        for ((i=0;i<4;i+=1)); do
        if [[ $i -lt $full_octets ]]; then
                mask+=255
        elif [[ $i -eq $full_octets ]]; then
                mask+=$((256 - 2**(8-$partial_octet)))
        else
                mask+=0
        fi
                test $i -lt 3 && mask+=.
        done
        echo $mask
}

getCidr() {
        #Expects an interface name to be passed.
        local cidr
        cidr=$(ip -f inet -o addr | grep $1 | awk -F'[ /]+' '/global/ {print $5}' | head -n2 | tail -n1)
        echo $cidr
}
mask2network() {
        #Expects IP address passed 1st, and Subnet Mask passed 2nd.
        OIFS=$IFS
        IFS='.'
        read -r i1 i2 i3 i4 <<< "$1"
        read -r m1 m2 m3 m4 <<< "$2"
        IFS=$OIFS
        printf "%d.%d.%d.%d\n"  "$((i1 & m1))" "$((i2 & m2))" "$((i3 & m3))" "$((i4 & m4))"
}
interface2broadcast() {
        #Expects interface name to be passed.
        broadcast=$(ip addr show |grep -w inet | grep $1 | awk '{ print $4}')
        printf $broadcast
}
subtract1fromAddress() {
        #Expects an IP address to be passed.
        #Subtracts 1 from passed IP.
        #Intended to find last valid IP Address on a subnet given a valid broadcast address.
        previousIFS=$IFS
	IFS=. read ip1 ip2 ip3 ip4 <<< "$1"
        if [[ $ip4 -gt 0 ]]; then
                let ip4-=1
        elif [[ $ip3 -gt 0 ]]; then
                let ip3-=1
                ip4=255
        elif [[ $ip2 -gt 0 ]]; then
                let ip2-=1
                ip3=255
                ip4=255
        elif [[ $ip1 -gt 0 ]]; then
                let ip1-=1
                ip2=255
                ip3=255
                ip4=255
        else
                #Not a valid IP or all 0s were passed.
                return 2
        fi
	IFS=$previousIFS
                printf $ip1.$ip2.$ip3.$ip4
}
addToAddress () {
        #IP Address is first argument.
        #Number to add is second argument.
        previousIFS=$IFS
        IFS=. read octet1 octet2 octet3 octet4 <<< "$1"
        IFS=$previousIFS
        maxOctetValue=256
        let octet4+=$2
        if [[ $octet4 -ge $maxOctetValue ]]; then
                numberToRollOver=$(( $octet4 / $maxOctetValue ))
                remainder=$(( $octet4 - (( $numberToRollOver * $maxOctetValue  ))))
                octet4=$remainder
                let octet3+=$numberToRollOver
                if [[ $octet3 -ge $maxOctetValue ]]; then
                        numberToRollOver=$(( $octet3 / $maxOctetValue ))
                        remainder=$(( $octet3 - (( $numberToRollOver * $maxOctetValue  ))))
                        octet3=$remainder
                        let octet2+=$numberToRollOver
                        if [[ $octet2 -ge $maxOctetValue ]]; then
                                numberToRollOver=$(( $octet2 / $maxOctetValue ))
                                remainder=$(( $octet2 - (( $numberToRollOver * $maxOctetValue  ))))
                                octet2=$remainder
                                let octet1+=$numberToRollOver
                                if [[ $octet1 -ge $maxOctetValue ]]; then
                                        #Ran out of IP addresses.
                                        return 1
                                fi
                        fi
                fi
        fi
        printf $octet1.$octet2.$octet3.$octet4
}
configureDHCP() {
        if [[ $OS == 1 || $OS == 2 ]]; then
        #Set dhcp config file location.
        dhcpFile=/etc/dhcp/dhcpd.conf
        fi      
        #Get mask and network for internal interface.
        externalMask=$( cidr2mask $(getCidr $externalName))
        internalMask=$( cidr2mask $(getCidr $internalName))
        externalNetwork=$( mask2network $externalIP $externalMask)
        internalNetwork=$( mask2network $internalIP $internalMask)
	firstAddress=$( addToAddress "$internalNetwork" "10")
	lastAddress=$( subtract1fromAddress $(interface2broadcast $internalName))




        #If the dhcp config file exists, delete it.
        if [[ -f $dhcpFile ]]; then
                rm -f $dhcpFile
        fi
        touch $dhcpFile
        echo 'use-host-decl-names on;' >> $dhcpFile
        echo 'ddns-update-style interim;' >> $dhcpFile
        echo 'ignore client-updates;' >> $dhcpFile
        echo " " >> $dhcpFile
        #Internal network
        echo 'subnet '$internalNetwork' netmask '$internalMask' {' >> $dhcpFile
        echo 'option subnet-mask '$internalMask';' >> $dhcpFile
        echo 'range dynamic-bootp '$firstAddress' '$lastAddress';' >> $dhcpFile
	echo 'default-lease-time 21600;' >> $dhcpFile
	echo 'max-lease-time 43200;' >> $dhcpFile
	echo 'option domain-name-servers '$MasterDNS','$SlaveDNS';' >> $dhcpFile
	echo 'option routers '$internalIP';' >> $dhcpFile
	echo '}' >> $dhcpFile

}
setupSelfHeal () {
if [[ -f $DIR/selfheal.sh ]]; then
	rm -f $DIR/selfheal.sh
fi
cp $currentDir/selfheal.sh $DIR/selfheal.sh
chmod +x $DIR/selfheal.sh
}

