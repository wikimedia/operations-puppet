#!/bin/bash
set -x

# Prevent non-root logins while the VM is being setup
# The ssh-key-ldap-lookup script rejects user logins when this file is present
echo "VM is work in progress" > /etc/block-ldap-key-lookup

echo 'Enabling console logging for puppet while it does the initial run'
echo 'daemon.* |/dev/console' > /etc/rsyslog.d/60-puppet.conf
restart rsyslog

# If we don't have a LVM volume group, we'll create it,
# and allocate the remainder of the disk to it,
if ! /sbin/vgdisplay -c vd
then
  echo 'Creating the volume group'
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
fi
# At this point, all (the rest of) our disk are belong to LVM.

project=`curl http://169.254.169.254/openstack/latest/meta_data.json/ | sed -r 's/^.*project_id\": \"//'  | sed -r 's/\".*$//g'`
ip=`curl http://169.254.169.254/1.0/meta-data/local-ipv4 2> /dev/null`
hostname=`hostname`

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
master="labs-puppetmaster.wikimedia.org"

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
#!/bin/sh
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

echo "$ip	$fqdn" >> /etc/hosts

/etc/init.d/nslcd restart
/etc/init.d/nscd restart
dpkg-reconfigure -fnoninteractive -pcritical openssh-server
/etc/init.d/ssh stop
/etc/init.d/ssh start
nscd -i hosts

# set mailname
echo $fqdn > /etc/mailname

puppet agent --enable
# Run puppet, twice.  The second time is just to pick up packages
#  that may have been unavailable in apt before the first puppet run
#  updated sources.list
apt-get update
puppet agent --onetime --verbose --no-daemonize --no-splay --show_diff --waitforcert=10 --certname=${fqdn} --server=${master}
apt-get update

# The standard precise ssh server isn't compatible with our puppetized
#  ssh config.  Grab the latest from the WMF repo, which should fix things
apt-get -y install openssh-server

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
