class mesos::slave(
    $zookeeper,
) {

    require_package('mesos')

    file { '/etc/mesos/zk':
        content => $zookeeper,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    service { 'mesos-master':
        ensure => stopped,
    }

    service { 'mesos-slave':
        ensure => running,
    }
}
