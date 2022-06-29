# SPDX-License-Identifier: Apache-2.0
# == Class calico
#
# Installs calico-cni and calicoctl
class calico(
    Stdlib::Host            $master_fqdn,
    String                  $calicoctl_username,
    String                  $calicoctl_token,
    String                  $calico_version     = '3',
) {
    file { '/etc/calico':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    case $calico_version {
        '3': {
            if debian::codename::le('buster') {
                apt::package_from_component { 'calico-future':
                    component => 'component/calico-future',
                    packages  => ['calicoctl', 'calico-cni'],
                }
            } else {
                apt::package_from_component { 'calico317':
                    component => 'component/calico317',
                    packages  => ['calicoctl', 'calico-cni'],
                }
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
