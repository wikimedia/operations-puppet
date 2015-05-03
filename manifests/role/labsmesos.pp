class role::labs::mesos::master {
    include misc::labsdebrepo

    $zookeeper = hiera('zookeeper', 'zk://marathon-zookeeper-01.eqiad.wmflabs:2181/mesos')

    class { '::mesos::master':
        zookeeper => $zookeeper,
        quorum    => hiera('quorum', 1),
    }
}

class role::labs::mesos::slave {
    include misc::labsdebrepo

    $zookeeper = hiera('zookeeper', 'zk://marathon-zookeeper-01.eqiad.wmflabs:2181/mesos')

    class { '::mesos::slave':
        zookeeper => $zookeeper,
    }
}
