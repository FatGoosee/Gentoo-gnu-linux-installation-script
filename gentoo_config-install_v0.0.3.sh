#! /bin/bash
sSCRIPT_VERSION="0.0.3"
sMOUNTPOINT="/mnt/files"                                                                                    						 						## path containing scripts

iMAKEOPTS="-j8"														                                        						                    	## makeoptimisations
iUSEFLAGS="dbus screencast systemd cryptsetup dist-kernel apparmor"				                            	                                        	## global useflags removing these useflags could break the script
iACCEPT_KEYWORDS=(false "**")										                						# enabled "accepted keywords"		        	## ~processor-architecture or ** for all architectures

#sLOCALE_CONFIG=
	iKEYMAP="de"
	iLOCALE=(2 "en_US." "it_IT.")											        						# locale entries "locale 1" "locale 2"
	iLOCALEencode="UTF-8"
			
#sDISK_CONFIG=
	iDEVICE="vda"
	sLUKS=(false "DoNotShow_Any1YourPa55word!" false)						    		    				# enabled "password" gpg-encrypted-keyfile
	iPARTTABLE="gpt"
	#sPARTITIONS=	
		iBOOT=("fat32" "0%" "512MiB")								                						# "filesystem" "start sector" "end sector"
		iGENTOO=("btrfs" "512MiB" "100%") 							    	        						# "filesystem" "start sector" "end sector"		## btrfs and ext4 should work

#iSYSTEM="uefi"														                																		## uefi only, use u-boot
iHOSTNAME="gentoo-gnulinux"
#sUSER_CONFIG=
	iDEFAULT=("sol" "DoNotShow_Any1YourPa55word!")					      									# "username" "password"							## enabled and sudo is forced, username has to be all lowercase
	iUSER=(0 "aksinya" "DoNotShow_Any1YourPa55word!" false "arvid" "DoNotShow_Any1YourPa55word!" false)		# user accounts "username" "password" sudo		## username has to be all lowercase

iPROFILE=("minimal" false)													                				# "minimal", "server" or "desktop" extra		## all profiles are based on minimal, desktop uses gnome. extra for server installs server-programms on docker, extra for desktop installs phosh
#sAUDIO_CONFIG="media-video/pipewire"
iKERNEL="gentoo"													                						# "gentoo" or "vanilla"
iADDITIONALpkgs=(2 "app-editors/neovim" "dev-vcs/git gpg")													# package entries "category/packagename useflags (useflags optional)" "category/packagename useflags (useflags optional)"	## specify 0 for no additional packages
#iNETWORK_CONIG="net-misc/networkmanager"
iTIMEZONE="Europe/Madrid"

iPRIVILEGE="sudo"																							# "sudo" or "doas"
iNIXPKGmgr=false													                						# false or true									## install nixpkgs
iMAC="apparmor"														                						# "apparmor" or "selinux"						## SELinux is recommended but currently does not work. Uses mls policy type.

. ${sMOUNTPOINT}/gentoo_setup-install_v${sSCRIPT_VERSION}.sh
