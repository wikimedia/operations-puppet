# == Class etcd::logging
#
# Manages all the logging logic for etcd.
class etcd::logging {

    logrotate::conf { '/etcd':
        ensure => present,
        source => 'puppet:///modules/etcd/logrotate.conf',
    }

    rsyslog::conf { 'etcd':
        source   => 'puppet:///modules/etcd/rsyslog.conf',
        priority => 20,
        require  => File['/etc/logrotate.d/etcd'],
    }
}
