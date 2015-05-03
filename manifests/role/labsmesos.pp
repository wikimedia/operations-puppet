class role::labs::mesos::master {
    include misc::labsdebrepo

    # Convert list of hostnames into hostname:8181,hostname:8181 format,
    # while making sure it works for just a single host too
    # This is because mesos doesn't support leaving out the port
    $zookeeper_hosts = join(keys(hiera('zookeeper_hosts')), ':2181,')
    $zookeeper_url = "zk://${zookeeper_hosts}:2181/mesos"

    class { '::mesos::master':
        zookeeper_url => $zookeeper_url,
        quorum       => hiera('quorum', 1),
    }
}

class role::labs::mesos::slave {
    include misc::labsdebrepo

    # Convert list of hostnames into hostname:8181,hostname:8181 format,
    # while making sure it works for just a single host too
    # This is because mesos doesn't support leaving out the port
    $zookeeper_hosts = join(keys(hiera('zookeeper_hosts')), ':2181,')
    $zookeeper_url = "zk://${zookeeper_hosts}:2181/mesos"

    class { '::mesos::slave':
        zookeeper_url => $zookeeper_url,
    }
}
