#!/bin/bash

chroot $1 echo '' > /etc/resolvconf/resolv.conf.d/original
chroot $1 passwd -ld root
chroot $1 passwd -ld ubuntu
chroot $1 printf "%s\t%s\t%s\t%s\n" cloud-init cloud-init/datasources multiselect  "ConfigDrive, Ec2" | debconf-set-selections
chroot $1 dpkg-reconfigure --frontend=noninteractive cloud-init
chroot $1 apt-get update
chroot $1 /root/install_sudo.sh
chroot $1 rm /root/install_sudo.sh
chroot $1 apt-get install -y puppet puppet-common facter glusterfs-client salt-minion
chroot $1 /etc/init.d/salt-minion stop
chroot $1 mv /etc/puppet/puppet.conf.install /etc/puppet/puppet.conf
chroot $1 mv /etc/default/puppet.install /etc/default/puppet
chroot $1 rm /etc/ssh/ssh_host*key*
chroot $1 sed -i '/^kernel/s/$/ console=ttyS0/' /boot/grub/menu.lst
chroot $1 sed -i 's/console=hvc0/xencons=hvc0 console=hvc0/' /boot/grub/menu.lst
chroot $1 rm -f /etc/sudo-ldap.conf
chroot $1 ln -s /etc/ldap/ldap.conf /etc/sudo-ldap.conf
chroot $1 useradd -r -d /var/lib/icinga -s /bin/false icinga
# Ensure last call doesn't return a bad exit code
echo ""
