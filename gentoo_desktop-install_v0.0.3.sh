#! /bin/bash
sSCRIPT_VERSION="0.0.3"
echo "" > desktopInstall.log

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

		printf "\n\n$?:\t$@\n" >> desktopInstall.log
		"$@" &>> desktopInstall.log
  }

sUNMASK="--autounmask-write --autounmask"
sEMERGE="emerge ${sUNMASK}"
desktopPkgUse ()
  	{
		echo "Setting package useflags..."
      		command echo "media-video/pipewire jack-sdk pipewire-alsa gst-plugin-pipewire echo-cancel flatpak lv2 modemmanager roc sound-server" > /etc/portage/package.use/pipewire
      		command echo "media-libs/mesa gles1 llvm opencl osmesa vdpau vulkan-overlay" > /etc/portage/package.use/mesa
      		command echo "VIDEO_CARDS=\"nouveau radeon radeonsi amdgpu vc4 virgl\"" >> /etc/portage/make.conf
      		command echo "media-libs/libcanberra alsa" > /etc/portage/package.use/libcanberra
      		command echo "dev-libs/libical vala" > /etc/portage/package.use/libical
      		command echo "dev-cpp/cairomm X" > /etc/portage/package.use/cairomm
  	}

installDesktoppkgs ()
  	{
    	echo "Installing desktop profile packages..."
      		if [ ${iPROFILE[1]} == true ]
		    	then
			      	command eselect repository enable guru
      		  		command emerge --sync
			      	command ${sEMERGE} phosh-base/phosh-base app-mobilephone/usb-tethering
        		fi
      		command ${sEMERGE} dev-libs/libical media-video/pipewire media-video/wireplumber media-libs/libpulse sys-apps/baobab gnome-base/gdm x11-themes/gnome-backgrounds gnome-extra/gnome-calculator gnome-extra/gnome-calendar gnome-extra/gnome-characters gnome-extra/gnome-clocks net-misc/gnome-connections gui-apps/gnome-console gnome-extra/gnome-contacts gnome-base/gnome-control-center sys-apps/gnome-disk-utility media-gfx/gnome-font-viewer gnome-extra/gnome-logs sci-geosciences/gnome-maps gnome-base/gnome-menus net-misc/gnome-remote-desktop gnome-extra/gnome-shell-extensions gnome-extra/gnome-software gnome-extra/gnome-system-monitor app-editors/gnome-text-editor gnome-extra/gnome-tweaks gnome-extra/gnome-user-docs gnome-extra/gnome-user-share gnome-extra/gnome-weather gnome-base/gvfs net-wireless/iwd media-libs/mesa media-libs/libva-compat gnome-base/nautilus app-accessibility/orca net-misc/rygel media-gfx/simple-scan sys-apps/smartmontools gnome-extra/sushi media-video/totem net-misc/wget net-wireless/wireless-tools x11-misc/xdg-user-dirs-gtk sys-apps/flatpak net-dns/avahi sys-auth/rtkit
			command flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
      		command libtool --finish /usr/lib64
      		command env-update
      		command source /etc/profile
      		if [ ${iMAC} == "selinux" ]
      			then
      				rlpkg -a -r
      			fi
  	}
  	
finishUpInstall ()
	{
		command gpasswd -a ${iDEFAULT[0]} plugdev
      	command gpasswd -a ${iDEFAULT[0]} audit
      	if [ ${iUSER[0]} == true ]
      		then
      			command gpasswd -a ${iUSER[1]} plugdev
      			command gpasswd -a ${iUSER[1]} audit
      		fi
      	command printf "[Desktop Entry]\nType=Application\nName=AppArmor Notify\nComment=Receive on screen notifications of AppArmor denials\nTryExec=aa-notify\nExec=aa-notify -p -s 1 -w 60 -f /var/log/audit/audit.log\nStartupNotify=false\nNoDisplay=true" > /etc/xdg/autostart/apparmor-notify.desktop
	}

desktopPkgUse
updateWorld
installDesktoppkgs
finishUpInstall
aliasLine
writeBashrc
enableServices
cleanUP

