class strongswan ($fqdn_pem) {
    package { [ 'strongswan', 'ipsec-tools' ]:
            ensure => present,
    }

    file { '/etc/ipsec.secrets':
            content => template('strongswan/ipsec.secrets.erb'),
            owner => 'root',
            group => 'root',
            mode => '0400',
            notify => Service['strongswan'],
            require => Package['strongswan'],
    }

    file { '/etc/ipsec.conf':
            content => template('strongswan/ipsec.conf.erb'),
            owner => 'root',
            group => 'root',
            mode => '0444',
            notify => Service['strongswan'],
            require => Package['strongswan'],
    }

    file { "/etc/ipsec.d/cacerts/ca.pem":
        owner => 'root',
        group => 'root',
        mode => '0444',
        ensure => present,
        source => "/var/lib/puppet/ssl/certs/ca.pem",
        notify => Service['strongswan'],
        require => Package['strongswan'],
    }

    file { "/etc/ipsec.d/certs/${fqdn_pem}":
        owner => 'root',
        group => 'root',
        mode => '0444',
        ensure => present,
        source => "/var/lib/puppet/ssl/certs/${fqdn_pem}",
        notify => Service['strongswan'],
        require => Package['strongswan'],
    }

    file { "/etc/ipsec.d/private/${fqdn_pem}":
        owner => 'root',
        group => 'root',
        mode => '0444',
        ensure => present,
        source => "/var/lib/puppet/ssl/private_keys/${fqdn_pem}",
        notify => Service['strongswan'],
        require => Package['strongswan'],
    }

    $svcname = $::lsbdistcodename ? {
        # in Ubuntu/Trusty this service is /etc/init/strongswan.conf
        # in Ubuntu/Precise and Debian/Jessie it's /etc/init.d/ipsec
        'trusty'  => 'strongswan',
        'precise' => 'ipsec',
        'jessie'  => 'ipsec',
        default   => 'ipsec',
    }
    service { 'strongswan':
        name => $svcname,
        pattern => "charon",  # Strongswan IKEv2 daemon is called charon
        ensure => running,
        enable => true,
        hasstatus => true,
        hasrestart => true,
    }
}
