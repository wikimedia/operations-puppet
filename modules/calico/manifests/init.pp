# SPDX-License-Identifier: Apache-2.0
# == Class calico
#
# Installs calico-cni and calicoctl
class calico (
    Stdlib::Host                   $master_fqdn,
    String                         $calicoctl_username,
    Hash[String, Stdlib::Unixpath] $auth_cert,
    Calico::CalicoVersion          $version,
) {
    file { '/etc/calico':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    # FIXME: Was added for testing in T365687, can be removed
    file { '/etc/calico/pki':
        ensure => absent,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    $component_title = "calico${regsubst($version, '\\.', '')}"
    $version_array = $version.split('\\.')
    $minor_version = Integer($version_array[1])
    $next_version = "${$version_array[0]}.${$minor_version + 1}"
    apt::package_from_component { $component_title:
        component => "component/${component_title}",
        packages  => {
            'calicoctl'  => ">=${version} <${next_version}",
            'calico-cni' => ">=${version} <${next_version}",
        },
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
