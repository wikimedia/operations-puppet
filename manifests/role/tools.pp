# Roles for Kubernetes and co on Tool Labs
class role::toollabs::docker::registry {
    include ::toollabs::infrastructure

    require role::labs::lvm::srv

    class { '::docker::registry':
        datapath => '/srv/registry',
    }
}

class role::toollabs::etcd::k8s {
    include ::etcd
    include base::firewall

    $peer_nodes = join(hiera('k8s::etcd_hosts'), ' ')
    $k8s_master = hiera('k8s::master_host')

    ferm::service { 'etcd-clients':
        proto  => 'tcp',
        port   => '2379',
        srange => "@resolve((${k8s_master} ${peer_nodes}))"
    }

    ferm::service { 'etcd-peers':
        proto  => 'tcp',
        port   => '2380',
        srange => "@resolve((${peer_nodes}))"
    }
}

class role::toollabs::etcd::flannel {
    include ::etcd

    include base::firewall

    $worker_nodes = join(hiera('k8s::worker_hosts'), ' ')
    $peer_nodes = join(hiera('flannel::etcd_hosts'), ' ')
    $proxy_nodes = join(hiera('toollabs::proxy::proxies'), ' ')

    ferm::service { 'flannel-clients':
        proto  => 'tcp',
        port   => '2379',
        srange => "@resolve((${worker_nodes} ${peer_nodes} ${proxy_nodes}))"
    }

    ferm::service { 'flannel-peers':
        proto  => 'tcp',
        port   => '2380',
        srange => "@resolve((${peer_nodes}))"
    }
}

class role::toollabs::puppet::master {
    include ::toollabs::infrastructure
    include ::toollabs::puppetmaster
}

class role::toollabs::k8s::master {
    include base::firewall
    include toollabs::infrastructure

    include ::etcd

    $master_host = hiera('k8s::master_host', $::fqdn)
    $etcd_url = join(prefix(suffix(hiera('k8s::etcd_hosts'), ':2379'), 'https://'), ',')

    class { 'k8s::apiserver':
        master_host  => $master_host,
        etcd_servers => $etcd_url,

    }
    class { 'k8s::scheduler': }

    class { 'k8s::controller': }

    # FIXME: Setup TLS properly, disallow HTTP
    ferm::service { 'apiserver-http':
        proto => 'tcp',
        port  => '8080',
    }

    ferm::service { 'apiserver-https':
        proto => 'tcp',
        port  => '6443',
    }
}

class role::toollabs::k8s::worker {
    # NOTE: No base::firewall!
    # ferm and kube-proxy will conflict
    include toollabs::infrastructure

    $master_host = hiera('k8s::master_host')
    $etcd_url = join(prefix(suffix(hiera('flannel::etcd_hosts', [$master_host]), ':2379'), 'https://'), ',')

    ferm::service { 'flannel-vxlan':
        proto => udp,
        port  => 8472,
    }

    class { '::k8s::flannel':
        etcd_endpoints => $etcd_url,
    }

    class { '::k8s::docker':
        require => Class['::k8s::flannel'],
    }

    class { 'k8s::kubelet':
        master_host => $master_host,
        require     => Class['::k8s::docker'],
    }

    class { 'k8s::proxy':
        master_host => $master_host,
        require     => Class['::k8s::kubelet']
    }

}

class role::toollabs::k8s::webproxy {

    $master_host = hiera('k8s_master')
    $etcd_url = join(prefix(suffix(hiera('flannel::etcd_hosts'), ':2379'), 'https://'), ',')

    ferm::service { 'flannel-vxlan':
        proto => udp,
        port  => 8472,
    }

    class { '::k8s::flannel':
        etcd_endpoints => $etcd_url,
    }

    class { '::toollabs::kube2proxy':
        master_host => $master_host,
    }

    class { 'k8s::proxy':
        master_host => $master_host,
    }

}

class role::toollabs::k8s::bastion {

    # kubectl and things
    include k8s::client
}

# == Class: role::toollabs::elasticsearch
#
# Provisions Elasticsearch node with nginx reverse proxy
#
class role::toollabs::elasticsearch {
    include ::base::firewall
    include ::elasticsearch

    class { '::nginx':
        variant => 'light',
    }

    $auth_realm = 'Elasticsearch protected actions'
    $auth_file = '/etc/nginx/elasticsearch.htpasswd'
    nginx::site { 'elasticsearch':
        content => template('labs/toollabs/elasticsearch/nginx.conf.erb'),
    }

    file { '/etc/nginx/elasticsearch.htpasswd':
        ensure  => present,
        owner   => 'root',
        group   => 'www-data',
        mode    => '0440',
        content => secret('labs/toollabs/elasticsearch/htpasswd'),
        require => Class['nginx'],
    }

    ferm::service{ 'nginx-http':
        proto   => 'tcp',
        port    => 80,
        notrack => true,
    }

    $unicast_hosts = hiera('elasticsearch::unicast_hosts')
    $unicast_hosts_ferm = join($unicast_hosts, ' ')
    ferm::service { 'logstash_elastic_internode':
        proto   => 'tcp',
        port    => 9300,
        notrack => true,
        srange  => "@resolve((${unicast_hosts_ferm}))",
    }
}
