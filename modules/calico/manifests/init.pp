# SPDX-License-Identifier: Apache-2.0
# == Class calico
#
# Installs calico-cni and calicoctl
class calico (
    Stdlib::Host                   $master_fqdn,
    String                         $calicoctl_username,
    Hash[String, Stdlib::Unixpath] $auth_cert,
    Calico::CalicoVersion          $calico_version     = '3.17',
) {
    file { '/etc/calico':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    $component_title = "calico${regsubst($calico_version, '\\.', '')}"
    apt::package_from_component { $component_title:
        component => "component/${component_title}",
        packages  => ['calicoctl', 'calico-cni'],
    }

    # Create a kubeconfig for calicoctl to use.
    $kubeconfig = '/etc/calico/calicoctl-kubeconfig'
    k8s::kubeconfig { $kubeconfig:
        master_host => $master_fqdn,
        username    => $calicoctl_username,
        auth_cert   => $auth_cert,
    }

    file { '/etc/calico/calicoctl.cfg':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('calico/calicoctl.cfg_v3.erb'),
    }
}
