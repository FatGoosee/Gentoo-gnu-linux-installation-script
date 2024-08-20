#! /bin/bash
sSCRIPT_VERSION="0.0.2"
echo "" > setupExit1.log

die () 
	{
		umount /mnt/gentoo/boot
		umount /mnt/gentoo/home
		umount /mnt/gentoo
		exit 1
	}

command ()
	{
        "$@"
  		
		printf "\n\n$?:\t$@\n\t\t" >> setupInstall.log
		"$@" &>> setupInstall.log
	}


formatDisk ()
	{
    	echo "Formating disk..."
			command parted -s /dev/${iDEVICE} mklabel ${iPARTTABLE}
			command parted -s /dev/${iDEVICE} mkpart primary ${iBOOT[0]} ${iBOOT[1]} ${iBOOT[2]}
			command parted -s /dev/${iDEVICE} mkpart primary ${iGENTOO[0]} ${iGENTOO[1]} ${iGENTOO[2]}
			command parted -s /dev/${iDEVICE} name 1 boot
			command parted -s /dev/${iDEVICE} name 2 gentoo
			command parted -s /dev/${iDEVICE} set 1 boot on
	}

stage3 ()
	{
    	command tar xpvf ${sMOUNTPOINT}/stage3-*.tar.xz -C /mnt/gentoo --xattrs-include='*.*' --numeric-owner
	}
createFilesystem ()
	{
	    echo "Creating filesystem..."
			command mkfs.vfat -F32 /dev/${iDEVICE}1
			if [ ${iSYSTEM} == "uefi" ]
				then
					if [ ${sLUKS[0]} == true ]
						then
							iLUKS="mapper/luksdev"
		          			command printf "${sLUKS[1]}\n" | cryptsetup luksFormat -q -c aes-xts-plain64 -s 512 /dev/${iDEVICE}2
		          			command printf "${sLUKS[1]}\n" | cryptsetup luksOpen /dev/${iDEVICE}2 luksdev
		      		else
		          			iLUKS="${iDEVICE}2"
		        		fi
		  	else
		      		iLUKS="${iDEVICE}2"
		     	fi
		  	command mkfs.${iGENTOO[0]} -f -L gentoo /dev/${iLUKS}
		    
		  	if [ ${iGENTOO[0]} == "btrfs" ]
		    	then
		    		echo "Creating subvolumes..."
						command mkdir /mnt/gentoo
		        		command mount /dev/${iLUKS} /mnt/gentoo
		        		command btrfs subvolume create /mnt/gentoo/@
		        		command btrfs subvolume create /mnt/gentoo/@home
		        		command umount -f /mnt/gentoo
		        		command mount -t btrfs -o defaults,noatime,compress=zstd,discard=async,subvol=@ /dev/${iLUKS} /mnt/gentoo
		        		stage3
		        		command mount -t btrfs -o defaults,noatime,compress=zstd,discard=async,subvol=@home /dev/${iLUKS} /mnt/gentoo/home
		  	else
		    		command mount -t ${iGENTOO[0]} -o defaults,noatime /dev/${iLUKS} /mnt/gentoo
		    		stage3
		    	fi
      		command mount /dev/${iDEVICE}1 /mnt/gentoo/boot
	}


setupSystem ()
	{
    	command sed -i '/COMMON_FLAGS=/c\COMMON_FLAGS="-march=native -O2 -pipe"' /mnt/gentoo/etc/portage/make.conf
	  	command echo "" >> /mnt/gentoo/etc/portage/make.conf
	  	command echo "MAKEOPTS=\"${iMAKEOPTS}\"" >> /mnt/gentoo/etc/portage/make.conf
    	command echo "USE=\"${iUSEFLAGS}\"" >> /mnt/gentoo/etc/portage/make.conf
    	command echo 'ACCEPT_LICENSE="*"' >> /mnt/gentoo/etc/portage/make.conf
    	command cp --dereference /etc/resolv.conf /mnt/gentoo/etc/
		command cp ${sMOUNTPOINT}/gentoo_config-install_v${sSCRIPT_VERSION}.sh /mnt/gentoo
		command cp ${sMOUNTPOINT}/gentoo_minimal-install_v${sSCRIPT_VERSION}.sh /mnt/gentoo
		command cp ${sMOUNTPOINT}/gentoo_${iPROFILE}-install_v${sSCRIPT_VERSION}.sh /mnt/gentoo
		command sed -i "/gentoo_setup-install/c\iLUKS=${iLUKS}" /mnt/gentoo/gentoo_config-install_v${sSCRIPT_VERSION}.sh
		command echo ". ./gentoo_minimal-install_v${sSCRIPT_VERSION}.sh" >> /mnt/gentoo/gentoo_config-install_v${sSCRIPT_VERSION}.sh
    	command genfstab -U /mnt/gentoo >> /mnt/gentoo/etc/fstab
  	}



echo "Starting installation process..."
formatDisk
createFilesystem
setupSystem


arch-chroot /mnt/gentoo /bin/bash ./gentoo_config-install_v${sSCRIPT_VERSION}.sh
