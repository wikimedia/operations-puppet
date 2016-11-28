# == Class calico::cni
#
# Installs and configure the cni plugins for calico.

class calico::cni {
    require ::calico

    package { 'cni':
        ensure => $::calico::cni_version,
    }

    package { 'calico-cni':
        ensure => $::calico::calico_cni_version,
    }

    $etcd_endpoints = $::calico::etcd::endpoints

    file { ['/etc/cni', '/etc/cni/net.d']:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/etc/cni/net.d/10-calico.conf':
        content => template('calico/cni.conf.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        before  => Package['calico-cni'],
    }
}
