#!/bin/bash

set -x

# Prevent non-root logins while the VM is being setup
# The ssh-key-ldap-lookup script rejects non-root user logins if this file
# is present.
echo "VM is work in progress" > /etc/block-ldap-key-lookup

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

# Get hostname and domain from metadata
hostname=`curl http://169.254.169.254/openstack/latest/meta_data.json/ | sed -r 's/^.*hostname\": \"//'  | sed -r 's/[\"\.].*$//g'`
project=`curl http://169.254.169.254/openstack/latest/meta_data.json/ | sed -r 's/^.*project_id\": \"//'  | sed -r 's/\".*$//g'`
ip=`curl http://169.254.169.254/1.0/meta-data/local-ipv4 2> /dev/null`

# from here on out make sure our hostname is the hostname from metadata:
hostnamectl set-hostname $hostname

# domain is the last two domain sections, e.g. eqiad.wmflabs
domain=`hostname -d | sed -r 's/.*\.([^.]+\.[^.]+)$/\1/'`

if [ -z $domain ]; then
   echo "hostname -d failed, trying to parse dhcp lease"
   domain=`grep "option domain-name " /var/lib/dhcp/dhclient.*.leases | head -n1 | cut -d \" -f2`
fi

if [ -z $domain ]; then
    echo "Unable to determine domain; all is lost."
    exit 1
fi


fqdn=${hostname}.${project}.${domain}
master="puppet"

sed -i "s/_PROJECT_/${project}/g" /etc/security/access.conf
sed -i "s/_FQDN_/${fqdn}/g" /etc/puppet/puppet.conf
sed -i "s/_MASTER_/${master}/g" /etc/puppet/puppet.conf

echo "$ip       $fqdn $hostname" >> /etc/hosts
echo $hostname > /etc/hostname

# This is only needed when running bootstrap-vz on
# a puppetmaster::self instance, and even then
# it isn't perfect
mkdir /var/lib/puppet/client

systemctl restart nscd.service
dpkg-reconfigure -fnoninteractive -pcritical openssh-server
systemctl restart ssh.service
nscd -i hosts

# set mailname
echo $fqdn > /etc/mailname

if [[ $domain = *"labtest"* ]]; then
# On labtest and labtestn need to use a proxy for apt
    echo 'Acquire::http::Proxy "http://208.80.153.75:5001";' > /etc/apt/apt.conf.d/01proxy
    echo 'Acquire::https::Proxy "https://208.80.153.75:5001";' >> /etc/apt/apt.conf.d/01proxy
fi

apt-get update
DEBIAN_FRONTEND=noninteractive DEBIAN_PRIORITY=critical apt-get --force-yes -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" upgrade

# Make sure nothing has leaked in certwise
rm -rf /var/lib/puppet/ssl

puppet agent --enable
# Run puppet, twice.  The second time is just to pick up packages
#  that may have been unavailable in apt before the first puppet run
#  updated sources.list
puppet agent --onetime --verbose --no-daemonize --no-splay --show_diff --waitforcert=10 --certname=${fqdn} --server=${master}

# Refresh ldap now that puppet has updated our ldap.conf
systemctl restart nslcd.service

apt-get update
puppet agent -t

# Ensure all NFS mounts are mounted
mount_attempts=1
until [ $mount_attempts -gt 10 ]
do
    echo "Ensuring all NFS mounts are mounted, attempt ${mount_attempts}"
    echo "Ensuring all NFS mounts are mounted, attempt ${mount_attempts}" >> /etc/block-ldap-key-lookup
    ((mount_attempts++))
    /usr/bin/timeout --preserve-status -k 10s 20s /bin/mount -a && break
    # Sleep for 10s before next attempt
    sleep 10
done

# Run puppet again post mounting NFS mounts (if all the mounts hadn't been mounted
# before, the puppet code that ensures the symlinks are created, etc may not
# have run)
puppet agent -t

# Remove the non-root login restriction
rm /etc/block-ldap-key-lookup
