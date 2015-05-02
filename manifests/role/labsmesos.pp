class role::labs::mesos(
    $zookeeper_url = 'zk://marathon-master-01.eqiad.wmflabs:2181/mesos',
) {
    include misc::labsdebrepo
}

class role::labs::mesos::master {

    include role::labs::mesos

    # Host zookeeper on itself
    include role::analytics::zookeeper::server

    class { '::mesos::master':
        zookeeper => $role::labs::mesos::zookeeper_url,
    }
}

class role::labs::mesos::slave {
    include role::labs::mesos
    class { '::mesos::slave':
        zookeeper => $role::labs::mesos::zookeeper_url,
    }

}