#!/bin/bash

chroot $1 mkdir -p /root/.ssh
chroot $1 echo 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAgEAqWmdNQm1reC0jxfBof510S6ffw/BDIXyFM38ij3PnkYEBOE4PB3KeHJN7NxUbWaXPBILxtqq5EUnCL9XQnDx82opCC9nChNO5KAoV3VqwNAAfh2UVFPt4PKLXiJjU9k76acp+s3i7uEG0wOVlsggjmbsiBq/Jwkne9oodhA75go1GVeDrP5WsXBGYcXXdjY8uU1P901YIatJoYYQSOOsGngGRZPUbTeFrGBaaoQsRCIiE1/byWs5yUuTbWjsBYDK+FoQsmmG5C98tN2g0llLhdbHTVutDEsvRLf28s3RGTTskfYhMgHbpA3coMIKvG8f2gWuk0wgMzI6G69BO87PsdyaS0aNn/DQILRBGaWTIbZwvjecCxXhXsJx0h1fdhTeXZAHljuY2s/7r8LXLk2eLzDi7RIO4PNtUrlRMZ9DgXFupfJXQSJiE54GCMHIHJ5qqGEveJFg7GZXlyxMDm2wUPyw2YYtQcM/RamnyEjakUM7X3eF45gY4ewabp+3IpP2iqkH3gz7IE/8aXtmqwa+SHNl1KxmGZ+9FFOuByM8wvDWaV320569ZGVAy9dxaH/mClLMx+xUKDxa4JN9dn9Yi+hnKoUhOYaBYXB+aPwydjTLMzp7rr1RgrLVGNk1R9WS2RHnEOSYxDmZbAht3v81F/c4mlzBQHQmXBKnNIxdHis= new_install' >>/root/.ssh/authorized_keys
chroot $1 chmod -R go= /root/.ssh
chroot $1 echo '' > /etc/resolvconf/resolv.conf.d/original
chroot $1 passwd -ld root
chroot $1 passwd -ld ubuntu
chroot $1 printf "%s\t%s\t%s\t%s\n" cloud-init cloud-init/datasources multiselect  "ConfigDrive, Ec2" | debconf-set-selections
chroot $1 dpkg-reconfigure --frontend=noninteractive cloud-init
chroot $1 apt-get update
chroot $1 /root/install_sudo.sh
chroot $1 rm /root/install_sudo.sh
chroot $1 apt-get install -y puppet puppet-common facter nfs-client salt-minion
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
