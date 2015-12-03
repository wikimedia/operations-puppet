# Roles for Kubernetes and co on Tool Labs
class role::toollabs::etcd {
    include role::toollabs::puppet::client

    # To deny access to etcd - atm the kubernetes master
    # and etcd will be on the same host, so ok to just deny
    # access to everyone else
    include base::firewall
    include toollabs::infrastructure

    include role::toollabs::puppet::client

    include etcd

    ferm::service{'etcd-clients':
        proto  => 'tcp',
        port   => hiera('etcd::client_port', '2379'),
    }
}

class role::toollabs::docker::registry {
    include role::toollabs::puppet::client
    include ::toollabs::infrastructure

    require role::labs::lvm::srv

    class { '::docker::registry':
        datapath => '/srv/registry',
    }
}

class role::toollabs::puppet::master {
    include ::toollabs::infrastructure
    include ::toollabs::puppetmaster
}

class role::toollabs::puppet::client(
    $puppetmaster,
) {
    class { '::puppet::self::client':
        server => $puppetmaster,
    }
}

class role::toollabs::k8s::master {
    include role::toollabs::puppet::client
    # This requires that etcd is on the same host
    # And is not HA. Will re-evaluate when it is HA

    include base::firewall
    include toollabs::infrastructure

    include role::toollabs::etcd

    $master_host = hiera('k8s_master', $::fqdn)
    $etcd_url = join(prefix(suffix(hiera('etcd_hosts', [$::fqdn]), ':2379'), 'https://'), ',')

    class { 'k8s::apiserver':
        master_host => $master_host,
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
    include role::toollabs::puppet::client
    # NOTE: No base::firewall!
    # ferm and kube-proxy will conflict

    include toollabs::infrastructure
    require k8s::docker

    $master_host = hiera('k8s_master')
    $etcd_url = join(prefix(suffix(hiera('etcd_hosts', [$master_host]), ':2379'), 'https://'), ',')

    ferm::service { 'flannel-vxlan':
        proto => udp,
        port  => 8472,
    }

    class { '::k8s::flannel':
        etcd_endpoints => $etcd_url,
    }

    class { 'k8s::proxy':
        master_host => $master_host,
    }

    class { 'k8s::kubelet':
        master_host => $master_host,
    }
}

class role::toollabs::k8s::webproxy {
    include role::toollabs::puppet::client

    $master_host = hiera('k8s_master')
    $etcd_url = join(prefix(suffix(hiera('etcd_hosts', [$master_host]), ':2379'), 'https://'), ',')

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
    include role::toollabs::puppet::client

    # kubectl and things
    include k8s::client
}

# == Class: role::toollabs::elasticsearch
#
# Provisions Elasticsearch node with nginx reverse proxy
#
class role::toollabs::elasticsearch {
    include ::role::toollabs::puppet::client
    include ::base::firewall
    include ::elasticsearch

    class { '::nginx':
        variant => 'light',
    }

    nginx::site { 'elasticsearch':
        source => 'puppet:///files/labs/toollabs/elasticsearch/nginx.conf',
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
