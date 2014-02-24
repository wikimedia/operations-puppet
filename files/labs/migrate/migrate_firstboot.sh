#!/bin/bash
set -x

FLAG="/var/log/migratefirstboot.log"
if [ ! -f $FLAG ]; then
    ip=`hostname -i`
    if ( grep "eqiad" /etc/resolv.conf ); then
        echo "Detected first boot in eqiad."

        echo "Updating puppet host and cert"
        id=`curl http://169.254.169.254/1.0/meta-data/instance-id 2> /dev/null`
        idfqdn=${id}.eqiad.wmflabs
        master=virt1000.wikimedia.org
        sed -i "s/virt0.wikimedia.org/${master}/g" /etc/puppet/puppet.conf
        sed -i "s/^certname = .*$/certname = ${idfqdn}/g" /etc/puppet/puppet.conf
        find /var/lib/puppet -type f -print0 |xargs -0r rm

        echo "forcing a puppet run"
        puppet agent --onetime --verbose --no-daemonize --no-splay --show_diff --waitforcert=10

        echo "Marking our work as done"
        touch $FLAG
    fi
fi
