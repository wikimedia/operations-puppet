# == Class calico::cni
#
# Installs and configure the cni plugins for calico.

class calico::cni(
    Stdlib::Host  $master_fqdn,
    String        $calico_cni_username,
    String        $calico_cni_token,
    String        $kubeconfig,
) {
    require ::calico

    file { ['/etc/cni', '/etc/cni/net.d']:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    case $::calico::calico_version {
        '2.2.0': {
            package { 'cni':
                ensure => $::calico::cni_version,
            }

            package { 'calico-cni':
                ensure => $::calico::calico_cni_version,
            }

            $etcd_endpoints = $::calico::etcd_endpoints
            $datastore_type = 'etcdv2'

            file { '/etc/cni/net.d/10-calico.conf':
                content => template('calico/cni.conf.erb'),
                owner   => 'root',
                group   => 'root',
                mode    => '0755',
                before  => Package['calico-cni'],
            }
        }
        '3': {
            # With calico 3, we generate a dedicated kubeconfig
            # TODO: Remove kubeconfig parameter after migration to calico 3
            #       and rename this to $kubeconfig.
            $cni_kubeconfig = '/etc/cni/net.d/calico-kubeconfig'
            k8s::kubeconfig { $cni_kubeconfig:
                master_host => $master_fqdn,
                username    => $calico_cni_username,
                token       => $calico_cni_token,
            }

            file { '/etc/cni/net.d/10-calico.conflist':
                content => template('calico/cni.conf_v3.erb'),
                owner   => 'root',
                group   => 'root',
                mode    => '0755',
            }
        }
        default: { fail('Unsupported calico version') }
    }

}
