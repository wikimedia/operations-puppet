# Class: profile::wmcs::services::oidentd::client
#
# Provision an oident service acting as a client to a proxy running on an
# upstram host.
#
class profile::wmcs::services::oidentd::client (
    $proxy = lookup('profile::wmcs::services::oidentd::client::proxy'),
){
    package { 'oidentd':
        ensure => present,
    }

    file { '/etc/oidentd.conf':
        ensure  => file,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/profile/wmcs/oidentd/client-oidentd.conf',
        require => Package['oidentd'],
    }

    file { '/etc/oidentd_masq.conf':
        ensure  => file,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/profile/wmcs/oidentd/oidentd_masq.conf',
        require => Package['oidentd'],
    }

    systemd::service { 'oidentd':
        ensure    => present,
        content   => systemd_template('wmcs/services/oidentd/client/oidentd'),
        restart   => false,
        subscribe => Package['oidentd'],
    }

    ferm::service { 'oidentd':
        proto => 'tcp',
        port  => 113,
    }
}

