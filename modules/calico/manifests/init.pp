# == Class calico
#
# Installs and runs calico-node (for calico version <3) and calicoctl
class calico(
    Stdlib::Host            $master_fqdn,
    String                  $calicoctl_username,
    String                  $calicoctl_token,
    String                  $calico_version     = '2.2.0',
    Optional[Stdlib::Host]  $registry           = undef,
    Optional[Array[String]] $etcd_endpoints     = undef,
) {
    file { '/etc/calico':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    case $calico_version {
        '2.2.0': {
            # TODO: Remove registry parameter after migration to calico 3
            # TODO: Remove etcd_endpoints parameter after migration to calico 3
            $datastore_type = 'etcdv2'
            $calicoctl_version = '1.2.0-1~wmf1'
            $calico_node_version = '1.2.0'
            $calico_cni_version = '1.8.3-1~wmf1'
            $cni_version = '0.3.0-1~wmf2'

            base::expose_puppet_certs { '/etc/calico':
                ensure          => present,
                provide_private => true,
                require         => File['/etc/calico'],
            }

            package { 'calicoctl':
                ensure => $calicoctl_version,
            }

            file { '/etc/calico/calicoctl.cfg':
                ensure  => present,
                owner   => 'root',
                group   => 'root',
                mode    => '0444',
                content => template('calico/calicoctl.cfg.erb'),
            }

            package { "${registry}/calico/node":
                ensure   => $calico_node_version,
                provider => 'docker',
            }

            systemd::service { 'calico-node':
                ensure  => present,
                content => systemd_template('calico-node'),
                restart => true,
                require => Package["${registry}/calico/node"],
            }
        }
        '3': {
            apt::package_from_component { 'calico-future':
                component => 'component/calico-future',
                packages  => ['calicoctl', 'calico-cni'],
            }

            # Create a kubeconfig for calicoctl to use.
            $kubeconfig = '/etc/calico/calicoctl-kubeconfig'
            k8s::kubeconfig { $kubeconfig:
                master_host => $master_fqdn,
                username    => $calicoctl_username,
                token       => $calicoctl_token,
            }

            file { '/etc/calico/calicoctl.cfg':
                ensure  => present,
                owner   => 'root',
                group   => 'root',
                mode    => '0444',
                content => template('calico/calicoctl.cfg_v3.erb'),
            }
        }
        default: { fail('Unsupported calico version') }
    }
}
