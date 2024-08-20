#! /bin/bash
sSCRIPT_VERSION="0.0.1"
echo "" > minimalInstall.log

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
		
		printf "\n\n$?:\t$@\n" >> minimalInstall.log
		"$@" &>> minimalInstall.log
	}

sUNMASK="--autounmask-write --autounmask"
sEMERGE="emerge ${sUNMASK}"
sync ()
	{
		echo "Syncing..."
			command source /etc/profile
			command systemctl daemon-reload
			command emerge-webrsync
			command emerge --sync
			command emerge --oneshot sys-apps/portage
			command emerge --sync
			command sed -i "/replace-unmodified=/c\replace-unmodified=yes" /etc/dispatch-conf.conf
			command mkdir /etc/config-archive
			command echo "pre-update" >> /etc/portage/conf-update.d
	}

pkgUse ()
	{
    	echo "Setting package useflags..."
      		command mkdir -p /etc/portage/package.{accept_keywords,license,mask,unmask,use}
      		if [ ${iPROFILE} != "minimal" ]
      			then
      				command sed -i "s/USE=\"/USE=\"bluetooth ffmpeg extra ieee1394 v4l\ /" /etc/portage/make.conf
      				if [ ${iPROFILE} == "desktop" ]
      					then
      						command sed -i "s/USE=\"/USE=\"wayland egl gnome gtk accessibility cups opengl vaapi vulkan zstd gles2 X\ /" /etc/portage/make.conf
      						#command echo "x11-libs/gtk+ -X" > /etc/portage/package.use/gtk+
      						command echo "dev-cpp/gtkmm X" > /etc/portage/package.use/gtkmm
      					fi
      			fi
	    	command echo "sys-kernel/installkernel dracut uki" > /etc/portage/package.use/installkernel
		    command echo "sys-apps/systemd boot resolvconf timesync" > /etc/portage/package.use/systemd
		    command echo "net-misc/networkmanager concheck connection-sharing wpa_supplicant modemmanager rp-pppoe nftables ofono wifi systemd-resolved" > /etc/portage/package.use/networkmanager
		    command echo "net-wireless/wpa_supplicant ap" > /etc/portage/package.use/wpa_supplicant
  	}

accept_keyword ()
  	{
    	if [ ${iACCEPT_KEYWORDS[0]} == true ]
		  	then
        		echo "Accepting keywords..."
  			  		command ${sEMERGE} dev-vcs/git dev-vcs/mercurial
    				command echo "ACCEPT_KEYWORDS=\"${iACCEPT_KEYWORDS[1]}\"" >> /etc/portage/make.conf
  			fi
  	}

installMAC ()
	{
		if [ ${iMAC} == "selinux" ]
			then
				echo "Setting up selinux..."
			  		command echo "POLICY_TYPES=\"mls\"" >> /etc/portage/make.conf
		  			command echo "tmpfs /tmp tmpfs defaults,noexec,nosuid,rootcontext=system_u:object_r:tmp_t:s0 0 0" >> /etc/fstab
			  		iTMP=$(command eselect profile list | grep -e "hardened/selinux/systemd" | grep -v "no-multilib" | cut -b 4-6)
			  		command eselect profile set ${iTMP#]*}
					command sed -i "s/USE=\"/USE=\"ubac unconfined unknown-perms selinux\ /" /etc/portage/make.conf
					command ${sEMERGE} sys-kernel/${iKERNEL}-kernel
			  		command export FEATURES="-selinux"
			  		command ${sEMERGE} --oneshot sec-policy/selinux-base
		  			command sed -i "/SELINUX=/c\SELINUX=permissive" /etc/selinux/config
		  			command sed -i "/SELINUXTYPE=/c\SELINUXTYPE=mls" /etc/selinux/config
		  			command export FEATURES="-selinux -sesandbox"
		  			command ${sEMERGE} --oneshot sec-policy/selinux-base sec-policy/selinux-base-policy
		  			command export FEATURES="-selinux -sesandbox"
		  			command ${sEMERGE} sys-apps/policycoreutils
		  			command echo "app-arch/gzip -selinux -sesandbox" > /etc/portage/package.use/gzip
		  			command emerge --update --deep --newuse @world
		  			command etc-update --automode -5
			  		command mkdir /mnt/gentoo
		  			command mount -o bind / /mnt/gentoo
		  			command setfiles -r /mnt/gentoo /etc/selinux/mls/contexts/files/file_contexts /mnt/gentoo/{dev,boot,proc,run,sys,tmp}
			  		command umount /mnt/gentoo
		  			command rlpkg -a -r
		  			command sed -i "/SELINUX=/c\SELINUX=enforcing" /etc/selinux/config
				  	command semanage login -a -s users_u ${iDEFAULT[0]}
				  	command restorecon -R -F /home/${iDEFAULT[0]}
				  	command semanage login -a -s users_u ${iUSER[1]}
				  	command restorecon -R -F /home/${iUSER[1]}
				  	command newrole -r sysadm_r
				  	command sed -i "/$%wheel\ ALL=(ALL)/c\%wheel\ ALL=(ALL)\ TYPE=sysadm_t\ ROLE=sysadm_r\ ALL" /etc/sudoers

			  		if [ ${iNIXPKGmgr} == true ]
						then
						  command semanage fcontext -a -t etc_t "/nix/store/[^/]+/etc(/.*)?"
						  command semanage fcontext -a -t lib_t "/nix/store/[^/]+/lib(/.*)?"
						  command semanage fcontext -a -t systemd_unit_file_t "/nix/store/[^/]+/lib/systemd/system(/.*)?"
						  command semanage fcontext -a -t man_t "/nix/store/[^/]+/man(/.*)?"
						  command semanage fcontext -a -t bin_t "/nix/store/[^/]+/s?bin(/.*)?"
						  command semanage fcontext -a -t usr_t "/nix/store/[^/]+/share(/.*)?"
						  command semanage fcontext -a -t var_run_t "/nix/var/nix/daemon-socket(/.*)?"
						  command semanage fcontext -a -t usr_t "/nix/var/nix/profiles(/per-user/[^/]+)?/[^/]+"
						  command mkdir /etc/systemd/system/nix-daemon.service.d
						  command echo "[Service]" >> /etc/systemd/system/nix-daemon.service.d/override.conf
						  command echo "Environment=\"NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt\"" >> /etc/systemd/system/nix-daemon.service.d/override.conf
						  command setenforce Permissive
						fi
		else
				command ${sEMERGE} sys-apps/apparmor sys-apps/apparmor-utils sys-libs/libapparmor
			fi
	}

installKernel ()
	{
    	command ${sEMERGE} sys-kernel/linux-firmware sys-kernel/${iKERNEL}-kernel sys-kernel/linux-headers sys-apps/fwupd sys-apps/kmod sys-fs/cryptsetup
		command eselect kernel set 1
    	command libtool --finish /usr/lib64
    	command ln -s /usr/src/$(ls /usr/src/) /usr/src/linux
  	}

installBasepkgs ()
	{
    	command ${sEMERGE} sys-apps/dbus app-shells/bash app-shells/bash-completion app-arch/bzip2 sys-apps/file sys-apps/coreutils sys-apps/findutils sys-apps/gawk sys-devel/gcc sys-devel/gettext sys-libs/glibc sys-apps/grep app-arch/gzip sys-apps/iproute2 net-misc/iputils sys-apps/pciutils sys-process/procps sys-process/psmisc sys-apps/sed sys-apps/shadow sys-apps/systemd app-arch/tar sys-apps/util-linux app-arch/xz-utils
    	command libtool --finish /usr/lib64
  	}

installKernel_essentials ()
  	{
    	command ${sEMERGE} sys-kernel/dracut sys-kernel/installkernel
    	command libtool --finish /usr/lib64
  	} 

installBasedevelpkgs ()
  	{
    	command ${sEMERGE} dev-build/autoconf dev-build/automake sys-devel/binutils sys-devel/bison dev-util/debugedit sys-apps/fakeroot sys-devel/flex sys-apps/groff dev-build/libtool
    	command libtool --finish /usr/lib64
    	command ${sEMERGE} sys-devel/m4 dev-build/make sys-devel/patch dev-util/pkgconf sys-apps/texinfo sys-apps/which sys-fs/btrfs-progs dev-build/cmake
    	command libtool --finish /usr/lib64
    	command ${sEMERGE} sys-process/audit app-misc/neofetch sys-fs/dosfstools sys-fs/cryptsetup net-misc/networkmanager net-dialup/rp-pppoe net-misc/modemmanager net-wireless/wpa_supplicant net-dns/dnsmasq app-admin/sudo net-misc/openssh sys-process/btop net-firewall/firewalld
    	command libtool --finish /usr/lib64
  	}

installEfipkgs ()
  	{
    	if [ ${iSYSTEM} == "uefi" ]
      		then
        		command ${sEMERGE} sys-boot/efibootmgr
      		fi
    	if [ "$(uname -m)" == "x86_64" ]
      		then
        		command echo "sys-firmware/intel-microcode initramfs intel-ucode" > /etc/portage/package.use/intel-microcode
        		command ${sEMERGE} sys-firmware/intel-microcode
      		fi
      	command libtool --finish /usr/lib64
  	}

timezoneSet ()
  	{
    	echo "Setting timezone..."
      		command ln -sf /usr/share/zoneinfo/${iTIMEZONE} /etc/localtime
      		command hwclock --systohc
      		command echo "[Time]" > /etc/systemd/timesyncd.conf
      		command echo "NTP=0.pool.ntp.org" >> /etc/systemd/timesyncd.conf
      		command echo "Fallback=0.gentoo.pool.ntp.org" >> /etc/systemd/timesyncd.conf
  	}

localeSet ()
  	{
    	echo "Setting locale..."
      		command echo "KEYMAP=${iKEYMAP}" >> /etc/conf.d/keymaps
      		for ((i = 1 ; i <= ${iLOCALE[0]} ; i++))
      			do
      				command echo "${iLOCALE[i]}${iLOCALEencode} ${iLOCALEencode}" >> /etc/locale.gen
      			done
      		command locale-gen
      		command echo "LANG=${iLOCALE[1]}${iLOCALEencode}" >> /etc/locale.conf
      		command env-update
      		command source /etc/profile
  	}

updateWorld ()
  	{
    	command emerge --update --deep --newuse --with-bdeps=y --keep-going @world
	    command emerge --depclean
  	}

hostnameSet ()
  	{
    	echo "Setting hostname..."
	    	command echo "${iHOSTNAME}" > /etc/hostname
  	}

systemBoot ()
	{
    	echo "Installing & configuring system bootmethod..."
    		command echo "add_dracutmodules+=\" crypt rootfs-block base dm btrfs systemd-ask-password \"" >> /etc/dracut.conf
      		if [ ${iSYSTEM} == "uefi" ]
        		then
        			command echo "uefi=\"yes\"" >> /etc/dracut.conf
          			if [ ${iLUKS} == "mapper/luksdev" ]
            			then
              				command echo "kernel_cmdline+=\" init=/usr/lib/systemd/systemd root=UUID=$(blkid -o value -s UUID /dev/${iLUKS}) rd.luks.uuid=$(blkid -o value -s UUID /dev/${iDEVICE}2) rootflags=subvol=@ \"" >> /etc/dracut.conf
			    	else
					    	command echo "kernel_cmdline+=\" init=/usr/lib/systemd/systemd root=UUID=$(blkid -o value -s UUID /dev/${iDEVICE}2) rootflags=subvol=@ rootfstype=btrfs \"" >> /etc/dracut.conf
				    	fi
				    if [ ${iMAC} == "selinux" ]
        				then
        					command sed -i "s/kernel_cmdline+=\"/kernel_cmdline+=\" lsm=selinux\ /" /etc/dracut.conf
        			else
        					command sed -i "s/kernel_cmdline+=\"/kernel_cmdline+=\" apparmor=1 security=apparmor\ /" /etc/dracut.conf
        				fi
			    	command dracut --regenerate-all --uefi
			    	command rm -f /boot/EFI/Linux/$(ls /boot/EFI/Linux/ | grep -v linux-)
			    	command bootctl install
	    	elif [ ${iSYSTEM} == "mobile" ]
		    	then
			    	command ${sEMERGE} dev-vcs/git
			    	command ${sEMERGE} emvedded/u-boot-tools
			    	command git clone https://source.denx.de/u-boot/u-boot.git
			    	command cd /u-boot
			    	command make ${sUBOOT}
			    	command make -j$(nproc)
			    	command DTC=/usr/bin/dtc make
			    	command echo "kernel_cmdline+=\" init=/usr/lib/systemd/systemd root=UUID=$(lsblk -o UUID /dev/${iDEVICE}2 | grep -v UUID) rootflags=subvol=@ rootfstype=btrfs \"" >> /etc/dracut.conf
			    	if [ ${iMAC} == "selinux" ]
        				then
        					command sed -i "s/kernel_cmdline+=\"/kernel_cmdline+=\" lsm=selinux\ /" /etc/dracut.conf
        			else
        					command sed -i "s/kernel_cmdline+=\"/kernel_cmdline+=\" apparmor=1 security=apparmor\ /" /etc/dracut.conf
        				fi
          			command dracut --regenerate-all
      		else
          			echo "Bios is not supported in this script, feel free to add it yourself"
          			die
        		fi
  	}

userSet ()
  	{
    	echo "Setting up user account(s)..."
    		command groupadd -r audit
        	command echo "log_group = audit" >> /etc/audit/auditd.conf
      		command useradd -G wheel,users,audit -m -U ${iDEFAULT[0]}
			command echo -e "${iDEFAULT[1]}\n${iDEFAULT[1]}" | passwd ${iDEFAULT[0]}
      		command echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers
      		command passwd --lock root
      		for ((i = 1 ; i <= ${iUSER[0]} ; i+=3))
      			do
      				if [ ${iUSER[i+2]} == true ]
      					then
      						sSUDO="wheel,"
      					fi
      				command useradd -G ${sSUDO}users,audit -m -U ${iUSER[i]}
      				command echo -e "${iUSER[i+1]}\n${iUSER[i+1]}" | passwd ${iUSER[i]}
      			done
    }

installNix ()
  	{
    	if [ ${iNIXPKGmgr} == true ]
      		then
        		#command yes | sh <(curl -L https://nixos.org/nix/install) --daemon
        		if [ ${iMAC} == "selinux" ]
          			then
            			command rm -f /etc/systemd/system/nix-daemon.{service,socket}
            			command cp /nix/var/nix/profiles/default/lib/systemd/system/nix-daemon.{service,socket} /etc/systemd/system/
            			command restorecon -RF /nix
            			command systemctl daemon-reload
            			command systemctl enable --now nix-daemon.socket
            			command setenforce Enforcing
          			fi
      		fi
  	}

installAddpkgs ()
  	{
    	for ((i = 1 ; i <= ${iADDITIONALpkgs[0]} ; i++))
      		do
        		sPKG=${iADDITIONALpkgs[i]# *}
        		sFILE=${sPKG#*/}
        		command echo "${iADDITIONALpkgs[i]}" > /etc/portage/package.use/${sFILE}
        		command libtool --finish /usr/lib64
        		command ${sEMERGE} ${sPKG}
        		if [ ${iMAC} == "selinux" ]
        			then
        				rlpkg ${sFILE}
        			fi
      		done
  	}


aliasLine ()
  	{
    	sSTARTA="neofetch && sudo emaint -a sync && sudo emerge -uDN @world && sudo etc-update --automode -5 && sudo emerge --depclean && sudo emerge --oneshot sys-apps/portage"
    	if [ ${iNIXPKGmgr} == true ]
      		then
        		sNIXA=" && sudo nix-env --upgrade"
      		fi
    	if [ ${iPROFILE} == "desktop" ]
      		then
        		sFLATPAKA=" && flatpak update -y"
      		fi
    	if [ ${iSYSTEM} == "uefi" ]
      		then
        		sINITRAMFSA="&& dracut --regenerate-all --uefi"
    	else
        		sINITRAMFSA="&& dracut --regenerate-all"
      		fi
    	sENDA="&& fwupdmgr refresh --force && fwupdmgr update && fwupdmgr install"
  	}

writeBashrc ()
  	{
		command echo "alias update='${sSTARTA}${sNIXA}${sFLATPAKA} ${sINITRAMFSA}'" >> /home/${iDEFAULT[0]}/.bashrc
    	command echo "alias update-uefi='${sSTARTA}${sNIXA}${sFLATPAKA} ${sINITRAMFSA} ${sENDA}'" >> /home/${iDEFAULT[0]}/.bashrc
    	command cp /home/${iDEFAULT[0]}/.bashrc /home/${iDEFAULT[0]}/.bashrc.backup
    	command echo "yes | sh <(curl -L https://nixos.org/nix/install) --daemon" >> /home/${iDEFAULT[0]}/.bashrc
    	command echo "mv /home/${iDEFAULT[0]}/.bashrc.backup /home/${iDEFAULT[0]}/.bashrc" >> /home/${iDEFAULT[0]}/.bashrc
  	}

enableServices ()
  	{
    	command systemctl enable firewalld systemd-timesyncd apparmor auditd NetworkManager
    	if [ ${iPROFILE} != "minimal" ]
      		then
        		command systemctl enable --global pipewire-pulse.socket wireplumber.service
        		if [ ${iPROFILE} == "desktop" ]
          			then
            			command systemctl enable gdm
          		else
          				command systemctl enable docker
          			fi
      		fi
    	command systemd-machine-id-setup
    	command systemd-firstboot --locale=${iLOCALE[1]}${iLOCALEencode} --keymap=${iKEYMAP} --timezone=${iTIMEZONE} --hostname=${iHOSTNAME}
    	command systemctl preset-all --preset-mode=enable-only
  	}

cleanUP ()
	{
		echo "#! /bin/bash" >> cleanUp.sh
		echo "rm -rf gentoo_*-install_v*.sh" >> cleanUp.sh
		. ./cleanUp.sh
	}


sync
pkgUse
timezoneSet
localeSet
accept_keyword
installKernel
installBasepkgs
installKernel_essentials
installBasedevelpkgs
installEfipkgs
updateWorld
hostnameSet
systemBoot
userSet
installMAC
#installNix
installAddpkgs


if [ ${iPROFILE} != "minimal" ]
	then
		. ./gentoo_${iPROFILE}-install_v${sSCRIPT_VERSION}.sh
else
    		aliasLine
	    	writeBashrc
	    	enableServices
	    	cleanUP
  	fi

