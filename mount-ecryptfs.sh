#!/bin/bash

LABEL=${1:-"IntHDD"}

FS_PATH="/run/media/"$USER"/"$LABEL
BLKDEV=$(/sbin/blkid -L $LABEL)
CRYPTED_PATH=$FS_PATH"/.secret"
DECRYPTED_PATH=~/$LABEL
ECRYPTFS_IS_MOUNTED=$(fgrep $DECRYPTED_PATH /etc/mtab | wc -l)
SUDO_PASSWORD=$(gpg --quiet --no-verbose -d < $FS_PATH"/.sudopassword.gpg")

function Get_Ecryptfs_Passphrase() {

	# How to generate a new PGP encrypted password file for an encryptfs folder
	# mkpasswd -S yoursalt -m sha-512 .secret | cut -b1-63  | gpg -evr youremail > $CRYPTED_PATH"/secretpassphrase.gpg"
	## Sugestions ##
	# yoursalt: A frase you'll never forget
	# .secret: My sugestion is to use the folder's name. So you can recreate the encrypt password if you lost the encrypted file.
	# cut -b1-63: Encryptfs password max size is 64 characters.
	# Any information that identifies your PGP public key. You can use your email here. (# gpg --list-public-keys)

	ECRYPTFS_PASSPHRASE=$(gpg --quiet --no-verbose  -d < ${CRYPTED_PATH}"/secretpassphrase.gpg")

	if [ $? -ne 0 ]; then
		echo "Error decrypting ${CRYPTED_PATH}/secretpassphrase.gpg"
		exit 1
	fi
}

function Mount_Ecryptfs() {

echo $SUDO_PASSWORD | sudo -S mount -t ecryptfs $CRYPTED_PATH $DECRYPTED_PATH -o \
key=passphrase:passphrase_passwd=${ECRYPTFS_PASSPHRASE},\
ecryptfs_cipher=aes,\
ecryptfs_key_bytes=16,\
ecryptfs_enable_filename_crypto=y,\
no_sig_cache,\
verbosity=0,\
ecryptfs_fnek_sig=ce27a6c78d42bbdd,\
ecryptfs_sig=ce27a6c78d42bbdd

	### DO NOT INDENT THE ABOVE LINES OR THE mount COMMAND WILL NOT WORK.

	if [ $? -ne 0 ]; then
		echo "Error mounting ecryptfs $CRYPTED_PATH on $DECRYPTED_PATH"
		exit 1
	fi

}

function Unmount_Ecryptfs() {

	if [ $ECRYPTFS_IS_MOUNTED != 0 ]; then

		sudo umount $DECRYPTED_PATH
		
		if [ $? -ne 0 ]; then
			echo "Error unmounting $DECRYPTED_PATH"
			exit 1
		else
			echo "Unmounted $DECRYPTED_PATH"
		fi	
	fi


}

function Start() {

	if [ $ECRYPTFS_IS_MOUNTED = 0 ]; then
	
		Get_Ecryptfs_Passphrase
		Mount_Ecryptfs		

	fi	
	
	if [ $ECRYPTFS_IS_MOUNTED != 0 ]; then

		Unmount_Ecryptfs
	
	fi
}

Start

exit 1
