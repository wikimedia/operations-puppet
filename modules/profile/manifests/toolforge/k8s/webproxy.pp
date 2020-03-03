class profile::toolforge::k8s::webproxy (
) {
    # workaround kube-proxy not playing well with iptables-nft
    if os_version('debian == buster') {
        alternatives::select { 'iptables':
            path    => '/usr/sbin/iptables-legacy',
        }
    }

    package { [
        'flannel',
        'kubernetes-node',
        'python3-pip',
        'python3-redis',
        'python3-requests',
    ]:
        ensure => absent,
    }

    systemd::service { 'kube2proxy':
        ensure  => absent,
        content => '',
    }

    file { '/usr/local/sbin/kube2proxy':
        ensure => absent,
    }

    file {'/etc/kube2proxy.yaml':
        ensure => absent,
    }
}
