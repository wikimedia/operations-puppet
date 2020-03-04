class profile::toolforge::k8s::client(
    $master_host = hiera('k8s::master_host'),
    $etcd_hosts = hiera('flannel::etcd_hosts', [$master_host]),
){
    class {'::toolforge::k8s::kubeadmrepo': }

    package {'kubernetes-client':
        ensure => absent,
    }

    package { 'kubectl':
        ensure => 'latest',
    }

    package { 'toollabs-webservice':
        ensure => latest,
    }

    # Legacy locations for the entry point script from toollabs-webservice
    # that are probably still hardcoded in some Tools.
    file { [
        '/usr/local/bin/webservice2',
        '/usr/local/bin/webservice',
    ]:
        ensure => link,
        target => '/usr/bin/webservice',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    # Kubernetes Configuration - See T209627
    if os_version('debian jessie') {
        $etcd_url = join(prefix(suffix($etcd_hosts, ':2379'), 'https://'), ',')

        ferm::service { 'flannel-vxlan':
            proto => udp,
            port  => 8472,
        }

        class { '::k8s::flannel':
            etcd_endpoints => $etcd_url,
        }

        class { '::k8s::infrastructure_config':
            master_host => $master_host,
        }

        class { '::k8s::proxy':
            master_host          => $master_host,
            metrics_bind_address => undef,
        }
    }
}
