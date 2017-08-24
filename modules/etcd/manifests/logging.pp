# == Class etcd::logging
#
# Manages all the logging logic for etcd.
class etcd::logging {

    logrotate::rule { 'etcd':
        ensure        => present,
        file_glob     => '/var/log/etcd.log',
        frequency     => 'daily',
        dateext       => true,
        dateyesterday => true,
        rotate        => 10,
        missingok     => true,
        nocreate      => true,
        compress      => true,
        post_rotate   => 'service rsyslog rotate >/dev/null 2>&1 || true',
    }

    rsyslog::conf { 'etcd':
        source   => 'puppet:///modules/etcd/rsyslog.conf',
        priority => 20,
        require  => File['/etc/logrotate.d/etcd'],
    }
}
