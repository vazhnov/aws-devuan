#!/bin/sh
#
# AWS EC2 instance cleanup for redistribution
#
# WARNING: BIOHAZARD!!!
# The instance will become unaccessible after this!
# Run only before creating AMI for distribution.
#
# maybe this could be replaced by bootstrap-vz:
# https://github.com/andsens/bootstrap-vz
# http://bootstrap-vz.readthedocs.io
#

# Make sure that I'm root
if [ $(id -u) -ne 0 ]; then
	printf "Need to be root!\n"
	exit 1
fi

if [ "$1" != "force" ]; then
	printf "WARNING:\n"
	printf "After shutdown, this instance will not be accessible anymore!\n"
	printf "Do not proceed, if not absolutely sure, that an AMI\n"
	printf "exported from this instance will start properly!!!\n\n"
	printf "This will remove all history, logs, and SSH keys!\n"
	printf "Instance will shutdown, can be exported as AMI and\n"
	printf "terminated afterwards.\n\n"
	printf "To proceed, run this with 'force' parameter.\n"
	exit
fi

# delete history
printf "Delete history ..."
rm -f /root/.bash_history 2>/dev/null
find /home -maxdepth 2 -type f -iname .bash_history -delete
find /home -type f -iname history -delete
find /home -type f -iname dead.letter -delete
find /root -type f -iname dead.letter -delete
printf "OK\n"

# delete package cache
printf "Delete apt cache ..."
aptitude --quiet=2 clean >/dev/null
printf "OK\n"

# Delete all SSH keys. New will be generated by cloud-init when spawning
# a new instance from AMI.
printf  "Delete SSH keys ..."
rm -f /etc/ssh/ssh_host_* 2>/dev/null
rm -f /root/.ssh/*
find /home -type f -iname authorized_keys -delete
printf "OK\n"

# stop log-creating services before deleting logfiles
printf "Stop services:\n"
sv stop $(find /etc/service/ -type l ! -iname 'ssh' ! -iname '*getty*')

printf "Delete logfiles ..."
rm -f /var/log/boot.log* /var/log/cloud-init*.log* /var/log/dmesg.log* \
 /var/log/apt/history.log* /var/log/apt/term.log* /var/log/hiawatha/* \
 /var/log/pure*.log /var/log/autorun*.log* /var/log/dpkg.log* /var/log/lastlog \
 /var/log/wtmp* /var/log/btmp* /var/backups/* \
 /var/log/amazon/ssm/*.log /var/log/aptitude 2>/dev/null
find /var/log -type f -iname current -delete
find /var/log -type f -iname '@*' -delete
find /var/log -type f -iname '*.gz' -delete
find /var/log -type f -iname '*.xz' -delete
printf "OK\n"

printf "Delete /var/lib/cloud/instances ..."
rm -rf /var/lib/cloud/instances/*
printf "OK\n"

printf "Delete /var/lib/amazon/ssm ..."
rm -rf /var/lib/amazon/ssm/*
printf "OK\n"

printf "\nAfter shutdown, instance can be exported as AMI.\n"
exit
