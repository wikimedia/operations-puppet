#!/bin/bash


##
## This chroots into $1 if provided, and self exec there
## with no arguments.
##
if [ "$1" != "" ]; then

  chroot $1 /bin/bash <$0
  echo ""

else

  ##
  ## This part of this script is run inside the chroot
  ##
  passwd -ld root
  passwd -ld ubuntu
  printf "%s\t%s\t%s\t%s\n" cloud-init cloud-init/datasources multiselect  "ConfigDrive, Ec2" | debconf-set-selections
  dpkg-reconfigure --frontend=noninteractive cloud-init
  apt-get update
  /root/install_sudo.sh
  rm /root/install_sudo.sh
  apt-get install -y puppet puppet-common facter nfs-client salt-minion lvm2
  /etc/init.d/salt-minion stop
  puppet agent --disable
  /etc/init.d/puppet stop
  /usr/bin/killall puppet
  mv /etc/puppet/puppet.conf.install /etc/puppet/puppet.conf
  mv /etc/default/puppet.install /etc/default/puppet
  rm /etc/ssh/ssh_host*key*
  sed -i 's/\/dev\/sda/\/dev\/vda/' /etc/fstab
  sed -i '/^kernel/s/$/ console=ttyS0/' /boot/grub/menu.lst
  sed -i 's/console=hvc0/xencons=hvc0 console=hvc0/' /boot/grub/menu.lst
  rm -f /etc/sudo-ldap.conf
  ln -s /etc/ldap/ldap.conf /etc/sudo-ldap.conf
  useradd -r -d /var/lib/icinga -s /bin/false icinga
  rm -f /etc/resolvconf/resolv.conf.d/original

fi

