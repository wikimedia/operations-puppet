class role::labs::mesos::master {
    include misc::labsdebrepo

    $zookeeper_hosts = join(suffix(keys(hiera('zookeeper_hosts')), ':2181'), ',')
    $zookeeper_url = "zk://${zookeeper_hosts}/mesos"

    class { '::mesos::master':
        zookeeper_url => $zookeeper_url,
        quorum       => hiera('quorum', 1),
    }

    class { '::mesos::marathon::master':
    }
}

class role::labs::mesos::slave {
    include misc::labsdebrepo

    $zookeeper_hosts = join(suffix(keys(hiera('zookeeper_hosts')), ':2181'), ',')
    $zookeeper_url = "zk://${zookeeper_hosts}/mesos"

    class { '::mesos::slave':
        zookeeper_url => $zookeeper_url,
    }
}

class role::labs::mesos::proxy {
    class { '::dynamicproxy':
        luahandler   => 'redundanturlproxy',
    }
}
