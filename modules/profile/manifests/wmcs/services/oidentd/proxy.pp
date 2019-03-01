# Class: profile::wmcs::services::oidentd::proxy
#
# Provision an oident service acting as a proxy for NAT masqueraded clients.
#
class profile::wmcs::services::oidentd::proxy {
    package { 'oidentd':
        ensure => present,
    }

    file { '/etc/oidentd.conf':
        ensure  => file,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/profile/wmcs/oidentd/proxy-oidentd.conf',
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
        content   => systemd_template('wmcs/services/oidentd/proxy/oidentd'),
        restart   => false,
        subscribe => Package['oidentd'],
    }

    ferm::service { 'oidentd':
        proto => 'tcp',
        port  => 113,
    }
}

