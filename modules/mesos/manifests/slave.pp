class mesos::slave(
    $zookeeper_url,
    $docker_registry,
) {

    require_package('mesos', 'lxc-docker')

    file { '/etc/mesos/zk':
        content => $zookeeper_url,
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

    file { '/etc/default/docker':
        content => template('mesos/docker.default.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        notify  => Service['docker']
    }

    service { 'docker':
        ensure => running,
    }

    service { 'mesos-master':
        ensure => stopped,
    }

    service { 'mesos-slave':
        ensure => running,
    }
}
