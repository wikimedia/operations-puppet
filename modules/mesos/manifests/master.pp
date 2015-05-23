class mesos::master(
    $zookeeper_url,
    $quorum,
) {

    require_package('mesos', 'marathon')

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

    file { '/etc/init/marathon.conf':
        source => 'puppet:///modules/mesos/marathon.conf',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        notify => Service['marathon']
    }

    file { '/etc/default/marathon':
        content => template('mesos/marathon.default.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['marathon'],
    }

    service { 'marathon':
        ensure => running,
    }
}
