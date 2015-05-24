class role::labs::mesos::master {
    include misc::labsdebrepo

    $zookeeper_hosts = join(suffix(keys(hiera('zookeeper_hosts')), ':2181'), ',')
    $zookeeper_url = "zk://${zookeeper_hosts}/mesos"
    $proxy_host = hiera('proxy_host', 'marathon-proxy-01')
    $proxy_hook_url = "http://${proxy_host}:8081/receive-hook"

    class { '::mesos::master':
        zookeeper_url  => $zookeeper_url,
        quorum         => hiera('quorum', 1),
        proxy_hook_url => $proxy_hook_url,
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
    include ::mesos::proxy
}
