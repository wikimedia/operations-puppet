class profile::ceph::k8s::node(
    Hash   $docker_settings = lookup('profile::ceph::k8s::docker::settings'),
    String $docker_version  = lookup('profile::ceph::k8s::docker::version'),
    String $k8s_pkg_release = lookup('profile::ceph::k8s::pkg_release'),
    String $k8s_version     = lookup('profile::ceph::k8s::version'),
    String $pause_image     = lookup('profile::ceph::k8s::pause_image'),
) {
    apt::repository { 'thirdparty-kubeadm-k8s':
        uri        => 'http://apt.wikimedia.org/wikimedia',
        dist       => 'buster-wikimedia',
        components => 'thirdparty/kubeadm-k8s',
    }

    class { 'docker::configuration':
        settings => $docker_settings,
    }

    class { 'docker':
        package_name => 'docker-ce',
        version      => $docker_version,
        require      => [
            Apt::Repository['thirdparty-kubeadm-k8s'],
            Exec['apt-get update']
        ],
    }

    package { 'kubeadm':
        ensure  => "${k8s_version}-${k8s_pkg_release}",
        require => Apt::Repository['thirdparty-kubeadm-k8s'],
    }
    package { 'kubectl':
        ensure  => "${k8s_version}-${k8s_pkg_release}",
        require => Apt::Repository['thirdparty-kubeadm-k8s'],
    }
    package { 'kubernetes-cni':
        ensure  => 'present',
        require => Apt::Repository['thirdparty-kubeadm-k8s'],
    }
    package { 'cri-tools':
        ensure  => 'present',
        require => Apt::Repository['thirdparty-kubeadm-k8s'],
    }
    package { 'ipset':
        ensure  => 'present',
        require => Apt::Repository['thirdparty-kubeadm-k8s'],
    }

    file { '/etc/default/kubelet':
        ensure  => 'present',
        mode    => '0444',
        content => "KUBELET_EXTRA_ARGS=\"--pod-infra-container-image=${pause_image}\""
    }

    # we require this in Buster because calico hardcodes iptables-legacy
    # calls, but otherwise it could work with the nf_tables backend.
    # We could pretty much do this the other way around: hack calico into
    # using iptables-nft (requires iptables 1.8.3)
    requires_os('debian == buster')

    alternatives::select { 'iptables':
        path    => '/usr/sbin/iptables-legacy',
        require => Package['docker-ce'], # iptables is a docker-ce dependency
    }
    alternatives::select { 'ip6tables':
        path    => '/usr/sbin/ip6tables-legacy',
        require => Package['docker-ce'], # iptables is a docker-ce dependency
    }

    alternatives::select { 'ebtables':
        path    => '/usr/sbin/ebtables-legacy',
        require => Package['kubeadm'],   # ebtables is a kubelet dependency, which is a kubeadm dep
    }
}
