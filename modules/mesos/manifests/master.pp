class mesos::master(
    $zookeeper,
    $quorum,
) {

    require_package('mesos')

    file { '/etc/mesos/zk':
        content => $zookeeper,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    file { '/etc/mesos-master/quorum':
        content => $quorum,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    service { 'mesos-master':
        ensure => running,
    }

    service { 'mesos-slave':
        ensure => stopped,
    }
}
