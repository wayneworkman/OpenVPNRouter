#Set working directories.
DIR=/opt/ovr
currentDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
speed=4
site=www.google.com
desiredInternalIP=192.168.1.1
desiredInternalMask=24
doDHCP=1
failuresBeforeReboot=1



#Source the functions script.
. "$currentDir/functions.sh"

if [[ ! -d $DIR ]]; then
	mkdir $DIR
fi

#get user input for setup.
displayMenus


#install packages required.
installPackages


#Check interfaces.
identifyInterfaces

return_code=$?

if [[ $return_code == 0 ]]; then
	echo In order to install OpenVPNRouter, you must have two interfaces available and one must have an active interface. Exiting.
	exit
fi


#Setup internal interface if it doesn't have an IP. 
setupInternalInterface

return_code=$?

if [[ $return_code == 0 ]]; then
        echo Exiting.
        exit
fi


#setup openVPN settings based on the chosen VPN Provider.
if [[ $VPN == 1 ]]; then
	setupPIA
fi

#Configure DHCP.
configureDHCP

#Set the services up.
initiateServices

#setup the self healing file
setupSelfHeal

#Additional self heal settings
additionalSelfHealSettings

#set paths inside self heal script
configurePaths

#Build the file that resets the routing and rules for the secific interfaces.
make_setiptables

#Setup cron event
setupCron


