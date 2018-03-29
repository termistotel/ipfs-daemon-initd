#!/bin/sh
# This file is part of the ipfs-daemon-initd project, 
# and is licensed under the MIT license
# Copyright 2015 Jeff Cochran


if [ "$EUID" -ne 0 ]; then
	echo 'This script must be run as root!'
	exit 1
fi

echo 'Finding ipfs...'

command -v /usr/local/bin/ipfs > /dev/null 2>&1
if [ 0 -eq $? ]; then
	IPFS_BIN_PATH=/usr/local/bin/ipfs
fi

if [ -z $IPFS_BIN_PATH ]; then
	command -v /usr/bin/ipfs > /dev/null 2>&1
	if [ 0 -eq $? ]; then
		IPFS_BIN_PATH=/usr/bin/ipfs
	fi
fi

if [ -z $IPFS_BIN_PATH ]; then
	which ipfs > /dev/null 2>&1
	if [ 0 -eq $? ]; then
		IPFS_BIN_PATH=`which ipfs`
	fi
fi

if [ -z $IPFS_BIN_PATH ]; then
	echo 'Unable to find IPFS binary!'
	echo 'Make sure it, or a link to it is on the path'
	echo ' or in a normal install location'
	exit 1
fi

echo "Found ipfs at $IPFS_BIN_PATH"

echo 'Creating daemon...'

useradd -r -m -d /ipfsd ipfsd

echo '[ipfs-daemon]' > /etc/ipfsd.conf
echo 'IPFS_BIN_PATH='"$IPFS_BIN_PATH" >> /etc/ipfsd.conf

echo 'Initializing ipfs...'
chmod o+rx $IPFS_BIN_PATH
HOME='/ipfsd'
MOUNTROOT='/mnt'
sudo -u ipfsd $IPFS_BIN_PATH init

echo 'Changing mounting points'
mkdir "$MOUNTROOT"/ipns
mkdir "$MOUNTROOT"/ipfs
chown ipfsd:ipfsd "$MOUNTROOT"/ipns
chown ipfsd:ipfsd "$MOUNTROOT"/ipfs
sed -i -e 's/"\/ipns"/"\'"$MOUNTROOT"'\/ipns"/g' /ipfsd/.ipfs/config
sed -i -e 's/"\/ipfs"/"\'"$MOUNTROOT"'\/ipfs"/g' /ipfsd/.ipfs/config

ln -s /ipfsd/.ipfs/logs /var/log/ipfs
ln -s /ipfsd/ipfsd.log /var/log/ipfsd.log

echo 'Adding init script...'

cp ./ipfsd /etc/init.d
chmod 755 /etc/init.d/ipfsd

# which update-rc.d > /dev/null 2>&1
# if [ 0 -eq $? ]; then
# 	update-rc.d ipfsd defaults
# 	echo 'Success'
# 	exit 0
# fi

command -v /usr/sbin/chkconfig > /dev/null 2>&1
if [ 0 -eq $? ]; then
	/usr/sbin/chkconfig --add ipfsd
	echo 'Success'
	exit 0
fi

echo 'Unable to automatically generate rc.d files. Refer to your OS manual to enable the ipfsd service at boot time. (sorry)'
echo 'Success'
exit 0
