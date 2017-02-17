# filtertags: labs-project-tools
class role::toollabs::k8s::master(
    $use_puppet_certs = false,
) {
    include ::base::firewall
    include ::toollabs::infrastructure

    $master_host = hiera('k8s::master_host', $::fqdn)
    $etcd_url = join(prefix(suffix(hiera('k8s::etcd_hosts'), ':2379'), 'https://'), ',')

    if $use_puppet_certs {
        # Do not explicitly set a before here, since it
        # seems to make puppet think there's a circular
        # dependency cycle?!
        base::expose_puppet_certs { '/etc/kubernetes':
            provide_private => true,
            user            => 'kubernetes',
            group           => 'kubernetes',
        }

        $ssl_cert_path = '/etc/kubernetes/ssl/cert.pem'
        $ssl_key_path = '/etc/kubernetes/ssl/server.key'

    } else {
        $ssl_certificate_name = 'star.tools.wmflabs.org'
        sslcert::certificate { $ssl_certificate_name:
            before       => Class['::k8s::apiserver'],
        }

        $ssl_cert_path = "/etc/ssl/localcerts/${ssl_certificate_name}.chained.crt"
        $ssl_key_path = "/etc/ssl/private/${ssl_certificate_name}.key"
    }

    class { '::k8s::apiserver':
        etcd_servers               => $etcd_url,
        use_package                => true,
        docker_registry            => hiera('docker::registry'),
        host_automounts            => ['/var/run/nslcd/socket'],
        ssl_cert_path              => $ssl_cert_path,
        ssl_key_path               => $ssl_key_path,
        host_path_prefixes_allowed => [
            '/data/project/',
            '/data/scratch/',
            '/public/dumps/',
        ],
    }

    class { '::toollabs::maintain_kubeusers':
        k8s_master => $master_host,
    }

    class { '::k8s::scheduler':
        use_package => true,
    }

    class { '::k8s::controller':
        use_package => true,
    }

    ferm::service { 'apiserver-https':
        proto => 'tcp',
        port  => '6443',
    }

    diamond::collector { 'Kubernetes':
        source => 'puppet:///modules/diamond/collector/kubernetes.py',
    }
}
