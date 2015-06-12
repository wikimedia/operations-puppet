#!/bin/bash
set -x

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

binddn=`grep 'binddn' /etc/ldap.conf | sed 's/.* //'`
bindpw=`grep 'bindpw' /etc/ldap.conf | sed 's/.* //'`
hostsou=`grep 'nss_base_hosts' /etc/ldap.conf | sed 's/.* //'`
id=`curl http://169.254.169.254/1.0/meta-data/instance-id 2> /dev/null`
ip=`curl http://169.254.169.254/1.0/meta-data/local-ipv4 2> /dev/null`
hostname=`hostname`
# domain is the last two domain sections, e.g. eqiad.wmflabs
domain=`hostname -d | sed -r 's/.*\.([^.]+\.[^.]+)$/\1/'`
idfqdn=${id}.${domain}
#TODO: get project a saner way
project=`ldapsearch -x -D ${binddn} -w ${bindpw} -b ${hostsou} "dc=${idfqdn}" puppetvar | grep 'instanceproject' | sed 's/.*=//'`
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

/etc/init.d/nslcd restart
/etc/init.d/nscd restart
dpkg-reconfigure -fnoninteractive -pcritical openssh-server
/etc/init.d/ssh stop
/etc/init.d/ssh start
nscd -i hosts

# set mailname
echo $fqdn > /etc/mailname

# Initial salt config
echo -e "master:\n  - ${master}\n  - ${master_secondary}" > /etc/salt/minion
echo "id: ${fqdn}" >> /etc/salt/minion
echo "master_finger: ${saltfinger}" >> /etc/salt/minion
echo "${fqdn}" > /etc/salt/minion_id
/etc/init.d/salt-minion restart

# Sleep until the nfs volumes we need are available.
#  Worst case, just time out after 3 minutes.
tries=18
for i in `seq 1 ${tries}`; do
    prod_domain=`echo $domain | sed 's/wmflabs/wmnet/'`
    nfs_server="labstore.svc.${prod_domain}"
    echo $(showmount -e ${nfs_server} | egrep ^/exp/project/${project}\\s), | fgrep -q $ip,
    if [ $? -eq 0 ];  then
        break
    fi
    sleep 10
done

if [ $i -eq $tries ]; then
    echo "Warning:  Timed out trying to detect NFS mounts."
fi

puppet agent --enable
# Force initial puppet run
puppet agent --onetime --verbose --no-daemonize --no-splay --show_diff --waitforcert=10 --certname=${fqdn} --server=${master}
