class mesos::slave(
    $zookeeper_slave,
) {

    require_package('mesos')

    file { '/etc/mesos/zk':
        content => $zookeeper_slave,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['mesos-slave'],
    }

    file { '/etc/default/mesos':
        source => 'puppet:///modules/mesos/mesos.default',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        notify => Service['mesos-slave'],
    }

    file { '/etc/default/mesos-slave':
        source => 'puppet:///modules/mesos/mesos-slave.default',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        notify => Service['mesos-slave'],
    }

    service { 'mesos-master':
        ensure => stopped,
    }

    service { 'mesos-slave':
        ensure => running,
    }
}
