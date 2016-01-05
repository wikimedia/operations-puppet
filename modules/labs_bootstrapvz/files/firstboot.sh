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
  script -c "/sbin/parted /dev/vda print fix" /dev/null

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

project=`curl http://169.254.169.254/openstack/latest/meta_data.json/ | sed -r 's/^.*project-id\": \"//'  | sed -r 's/\".*$//g'`
ip=`curl http://169.254.169.254/1.0/meta-data/local-ipv4 2> /dev/null`
hostname=`hostname`
# domain is the last two domain sections, e.g. eqiad.wmflabs
domain=`hostname -d | sed -r 's/.*\.([^.]+\.[^.]+)$/\1/'`
fqdn=${hostname}.${project}.${domain}
saltfinger="c5:b1:35:45:3e:0a:19:70:aa:5f:3a:cf:bf:a0:61:dd"
if [ "${domain}" == "eqiad.wmflabs" ]
then
	master="labs-puppetmaster-eqiad.wikimedia.org"
	master_secondary="labs-puppetmaster-codfw.wikimedia.org"
fi
if [ "${domain}" == "codfw.wmflabs" ]
then
	master="labs-puppetmaster-codfw.wikimedia.org"
	master_secondary="labs-puppetmaster-eqiad.wikimedia.org"
fi

# Finish LDAP configuration
sed -i "s/_PROJECT_/${project}/g" /etc/security/access.conf
sed -i "s/_PROJECT_/${project}/g" /etc/ldap/ldap.conf
sed -i "s/_PROJECT_/${project}/g" /etc/sudo-ldap.conf
sed -i "s/_PROJECT_/${project}/g" /etc/nslcd.conf
sed -i "s/_FQDN_/${fqdn}/g" /etc/puppet/puppet.conf
sed -i "s/_MASTER_/${master}/g" /etc/puppet/puppet.conf

# Set resolv.conf and stop anyone else from messing with it.
echo "" > /sbin/resolvconf
mkdir /etc/dhcp/dhclient-enter-hooks.d
cat > /etc/dhcp/dhclient-enter-hooks.d/nodnsupdate <<EOF
:#!/bin/sh
make_resolv_conf() {
        :
}
EOF

nameserver=`/usr/bin/dig +short labs-recursor0.wikimedia.org`
cat > /etc/resolv.conf <<EOF
domain ${project}.${domain}
search ${project}.${domain} ${domain}
nameserver ${nameserver}
options timeout:5 ndots:2
EOF

# This is only needed when running bootstrap-vz on
# a puppetmaster::self instance, and even then
# it isn't perfect
mkdir /var/lib/puppet/client

systemctl restart nslcd.service
systemctl restart nscd.service
dpkg-reconfigure -fnoninteractive -pcritical openssh-server
systemctl restart ssh.service
nscd -i hosts

# set mailname
echo $fqdn > /etc/mailname

# Initial salt config
echo -e "master:\n  - ${master}\n  - ${master_secondary}" > /etc/salt/minion
echo "id: ${fqdn}" >> /etc/salt/minion
echo "master_finger: ${saltfinger}" >> /etc/salt/minion
echo "${fqdn}" > /etc/salt/minion_id
systemctl restart salt-minion.service

puppet agent --enable
# Run puppet, twice.  The second time is just to pick up packages
#  that may have been unavailable in apt before the first puppet run
#  updated sources.list
puppet agent --onetime --verbose --no-daemonize --no-splay --show_diff --waitforcert=10 --certname=${fqdn} --server=${master}
apt-get update
puppet agent -t
