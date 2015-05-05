# == Class etcd::logging
#
# Manages all the logging logic for etcd.
class etcd::logging {

    file { '/etc/logrotate.d/etcd':
        source => 'puppet:///modules/etcd/logrotate.conf',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        before => Service['etcd'],
    }


    rsyslog::conf { 'etcd':
        source   => 'puppet:///modules/etcd/rsyslog.conf',
        priority => 20,
        require  => File['/etc/logrotate.d/etcd'],
        before   => Service['etcd']
    }
}
