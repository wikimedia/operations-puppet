# == Class calico
#
# Installs and runs calico-node and calicoctl
class calico(
    $etcd_endpoints,
    $registry,
    $calico_version='2.0',
) {
    requires_os('debian >= jessie')

    file { '/etc/calico':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    base::expose_puppet_certs { '/etc/calico':
        ensure          => present,
        provide_private => false,
        require         => File['/etc/calico'],
    }

    # Needed for calicoctl
    apt::pin { 'go':
        package  => 'golang-go-linux-amd64 golang-src',
        pin      => 'release a=jessie-backports',
        priority => '1001',
        before   => Package['calicoctl'],
    }


    case $calico_version {
        '2.0': {
            $calicoctl_version = '1.0.0-betarc5-1~wmf1'
            $calico_node_version = '1.0.0-beta-rc5'
            $calico_cni_version = '1.5.1-1~wmf1'
            $cni_version = '0.3.0-1~wmf1'
        }
        default: { fail('Unsupported calico version') }
    }

    package { 'calicoctl':
        ensure => $calicoctl_version,
    }

    package { "${registry}/calico/node":
        ensure   => $calico_node_version,
        provider => 'docker',
    }

    base::service_unit { 'calico-node':
        ensure  => present,
        systemd => true,
        require => Package["${registry}/calico/node"]
    }
}
