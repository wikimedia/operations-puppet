#!/bin/bash

echo 'Enabling console logging for puppet while it does the initial run'
echo 'daemon.* |/dev/console' > /etc/rsyslog.d/60-puppet.conf
restart rsyslog

# And, sleep some more.  This sucks but it helps avoid a race
# with NFS volume creation -- give NFS plenty of time
# to notice the new instance and set up exports.
sleep 60

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

puppet agent --enable

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

/etc/init.d/nslcd restart
/etc/init.d/nscd restart
dpkg-reconfigure -fnoninteractive -pcritical openssh-server
/etc/init.d/ssh stop
/etc/init.d/ssh start

# set mailname
echo $fqdn > /etc/mailname

# Initial salt config
echo -e "master:\n  - ${master}\n  - ${master_secondary}" > /etc/salt/minion
echo "id: ${idfqdn}" >> /etc/salt/minion
echo "master_finger: ${saltfinger}" >> /etc/salt/minion
/etc/init.d/salt-minion restart

# Force initial puppet run
puppet agent --onetime --verbose --no-daemonize --no-splay --show_diff --waitforcert=10 --certname=${idfqdn} --server=${master}
