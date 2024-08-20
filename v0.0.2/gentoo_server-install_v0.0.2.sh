#! /bin/bash
sSCRIPT_VERSION="0.0.2"
echo "" > serverInstall.log

die ()
	{
    	exit 1
  	}

command ()
  	{
		sUNMASK="--autounmask-write --autounmask"
		"$@"
		sUNMASK="--verbose=n"
		if [[ $(etc-update --automode -5) == *"Replacing"* ]]
			then
				"$@"		
			fi
		
		printf "\n\n$?:\t$@\n" >> serverInstall.log
		"$@" &>> serverInstall.log
  	}

sUNMASK="--autounmask-write --autounmask"
sEMERGE="emerge ${sUNMASK}"
serverPkgUse ()
  	{
    	echo "Setting package useflags..."
      		command echo "media-video/pipewire jack-sdk pipewire-alsa gst-plugin-pipewire echo-cancel lv2 modemmanager roc sound-server" > /etc/portage/package.use/pipewire
      		command echo "app-containers/docker btrfs" > /etc/portage/package.use/docker
  	}
 
installServerpkgs ()
  	{
    	echo "Installing server profile packages..."
      		if [ ${iSERVERdocker} == true ]
      			then
      				command ${sEMERGE} app-containers/docker app-containers/docker-cli
      				command libtool --finish /usr/lib64
      				command systemctl enable docker
      				command systemctl start docker
      				command printf "net.ipv4.ip_forward=1\net.ipv6.ip_forward=1" >> /etc/sysctl.d/local.conf
      				command docker create -t nginx-01 nginx
      		else
      				command ${sEMERGE} app-containers/docker app-containers/docker-cli www-server/nginx media-video/wireplumber media-video/pipewire media-libs/libpulse dev-db/postresql net-dns/avahi sys-auth/rtkit
      				command libtool --finish /usr/lib64
      			fi
      		if [ ${iMAC} == "selinux" ]
      			then
      				rlpkg -a -r
      			fi
  	}

serverPkgUse
updateWorld
installServerpkgs
aliasLine
writeBashrc
enableServices
cleanUP
