#!/bin/bash

echo 'Enabling console logging for puppet while it does the initial run'
echo 'daemon.* |/dev/console' > /etc/rsyslog.d/60-puppet.conf
restart rsyslog

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
if [ "${domain}" == "pmtpa.wmflabs" ]
then
	master="virt0.wikimedia.org"
	master_secondary="virt1000.wikimedia.org"
elif [ "${domain}" == "eqiad.wmflabs" ]
then
	master="virt1000.wikimedia.org"
	master_secondary="virt0.wikimedia.org"
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
