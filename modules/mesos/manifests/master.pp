class mesos::master(
    $zookeeper_url,
    $quorum,
) {

    require_package('mesos')

    file { '/etc/mesos/zk':
        content => $zookeeper_url,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['mesos-master'],
    }

    file { '/etc/mesos-master/quorum':
        content => $quorum,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['mesos-master'],
    }

    file { '/etc/default/mesos':
        source => 'puppet:///modules/mesos/mesos.default',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        notify => Service['mesos-master'],
    }

    file { '/etc/default/mesos-master':
        source => 'puppet:///modules/mesos/mesos-master.default',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        notify => Service['mesos-master'],
    }

    service { 'mesos-master':
        ensure => running,
    }

    service { 'mesos-slave':
        ensure => stopped,
    }
}
