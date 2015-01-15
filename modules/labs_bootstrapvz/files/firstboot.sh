#!/bin/bash

set -x

# Don't do anything until cloud-init has finished.
while [ ! -f /var/lib/cloud/instance/boot-finished ]
do
      sleep 1
done

echo 'Enabling console logging for puppet while it does the initial run'
echo 'daemon.* |/dev/console' > /etc/rsyslog.d/60-puppet.conf
systemctl restart rsyslog.service


# If we don't have a LVM volume group, we'll create it,
# and allocate the remainder of the disk to it,
if ! /sbin/vgdisplay -c vd
then
  echo 'Creating the volume group'
  # There seems to be a bug in boostrapvz that (can?)
  # create the gpt of the image with the "wrong" size,
  # where the extent of the disk is the sum of the
  # existing partitions rather than the actual size of
  # the image.  Sadly, the only way to fix this is
  # by invoking parted "interactively" and accept an
  # error if that is not the case (because then the
  # 'fix' parameter becomes an answer to a question
  # that is never asked.)
  /sbin/parted -s /dev/vda print fix >/dev/null 2>&1

  # the tail|sed|cut is just to get the start and
  # end of the last unpartitioned span on the disk
  /sbin/parted -s /dev/vda print
  /sbin/parted -ms /dev/vda print
  /sbin/parted -s /dev/vda print free
  /sbin/parted -ms /dev/vda print free
  if /sbin/parted -s /dev/vda mkpart primary $(
      /sbin/parted -ms /dev/vda print free |
      /usr/bin/tail -n 1 |
      /usr/bin/cut -d : -f 2,3 --output-delimiter=' '
    )
  then
    # this tail|cut is to to grab the partition
    # number of the space we just allocated (which
    # is, by necessity, the last partition
    part=$( /sbin/parted -ms /dev/vda print |
            /usr/bin/tail -n 1 |
            /usr/bin/cut -d : -f 1 )

    if [ "$part" != "" ]; then
      if [ "$part" -gt 1 ]; then
        /sbin/parted -s /dev/vda set $part lvm on
        /sbin/pvcreate /dev/vda$part
        /sbin/vgcreate vd /dev/vda$part
        /sbin/partprobe
      fi
    fi
  fi

  # Debian has an lvm bug that foils many a boot.  This hack should
  # work around that.
  sed -i '/GRUB_CMDLINE_LINUX_DEFAULT.*/c\GRUB_CMDLINE_LINUX_DEFAULT="console=ttyS0 rootdelay=20"' /etc/default/grub
  /usr/sbin/update-grub
fi
# At this point, all (the rest of) our disk are belong to LVM.

# If we don't have a swap partition, make one now
if ! /bin/egrep -q '^\S+\s+\S+\s+swap\s' /etc/fstab
then
  echo 'Creating swap volume'
  /sbin/lvcreate -L 2G -n swap vd
  /sbin/mkswap /dev/mapper/vd-swap
  echo "/dev/mapper/vd-swap none swap defaults 0 0" >>/etc/fstab
  /sbin/swapon -a
fi

# If we don't have a /var, we create it and /var/log,
# move everything to it, and forcibly reboot now to try
# everything anew
if ! /bin/egrep -q '^\S+\s+/var/log\s' /etc/fstab
then
  echo 'Creating /var/log volume'
  /sbin/lvcreate -L 2G -n log vd
  /sbin/mkfs -t ext4 /dev/mapper/vd-log
  /bin/mkdir -p /tmp/log
  /bin/mount /dev/mapper/vd-log /tmp/log
  /bin/tar cf - -C /var log | /bin/tar xf - -C /tmp
  /bin/umount /tmp/log
  echo "/dev/mapper/vd-log /var/log ext4 defaults 0 0" >>/etc/fstab

  # We're all done.  Now all that's left is to reboot making sure
  # that this script executes again.  This is done by remounting
  # / readonly before a forcible reboot - this way the file
  # used to tell rc.local to not execute firstboot.sh again can't
  # be created.

  /bin/sync
  /bin/mount -oro,remount /
  /sbin/reboot -f
fi

binddn=`grep 'binddn' /etc/ldap.conf | sed 's/.* //'`
bindpw=`grep 'bindpw' /etc/ldap.conf | sed 's/.* //'`
hostsou=`grep 'nss_base_hosts' /etc/ldap.conf | sed 's/.* //'`
id=`curl http://169.254.169.254/1.0/meta-data/instance-id 2> /dev/null`
hostname=`hostname`
domain=`hostname -d`
idfqdn=${id}.${domain}
fqdn=${hostname}.${domain}
#TODO: get project a saner way
project=`ldapsearch -x -D ${binddn} -w ${bindpw} -b ${hostsou} "dc=${idfqdn}" puppetvar | grep 'instanceproject' | sed 's/.*=//'`
saltfinger="c5:b1:35:45:3e:0a:19:70:aa:5f:3a:cf:bf:a0:61:dd"
if [ "${domain}" == "eqiad.wmflabs" ]
then
	master="virt1000.wikimedia.org"
	master_secondary="labcontrol2001.wikimedia.org"
fi

# Finish LDAP configuration
sed -i "s/_PROJECT_/${project}/g" /etc/security/access.conf
sed -i "s/_PROJECT_/${project}/g" /etc/ldap/ldap.conf
sed -i "s/_PROJECT_/${project}/g" /etc/sudo-ldap.conf
sed -i "s/_PROJECT_/${project}/g" /etc/nslcd.conf
sed -i "s/_FQDN_/${idfqdn}/g" /etc/puppet/puppet.conf
sed -i "s/_MASTER_/${master}/g" /etc/puppet/puppet.conf

# This is only needed when running bootstrap-vz on
# a puppetmaster::self instance, and even then
# it isn't perfect
mkdir /var/lib/puppet/client

puppet agent --enable

systemctl restart nslcd.service
systemctl restart nscd.service
dpkg-reconfigure -fnoninteractive -pcritical openssh-server
systemctl restart ssh.service

# set mailname
echo $fqdn > /etc/mailname

# Initial salt config
echo -e "master:\n  - ${master}\n  - ${master_secondary}" > /etc/salt/minion
echo "id: ${idfqdn}" >> /etc/salt/minion
echo "master_finger: ${saltfinger}" >> /etc/salt/minion
systemctl restart salt-minion.service

# Force initial puppet run
puppet agent --onetime --verbose --no-daemonize --no-splay --show_diff --waitforcert=10 --certname=${idfqdn} --server=${master}
