
class profile::waf::apache2::administrative {

    # Pin jessie hosts to jessie-backports for version 2.9
    if os_version('debian == jessie') {
        apt::pin { 'libapache2-mod-security2':
            pin      => 'release a=jessie-backports',
            package  => 'libapache2-mod-security2',
            priority => '1001',
            before   => Package['libapache2-mod-security2'],
        }
    }

    # Not using require_package so apt::pin may be applied
    # before attempting to install package.
    package { 'libapache2-mod-security2':
        ensure => present,
    }

    # Ensure that the CRS modsecurity ruleset is not used.
    file { '/etc/apache2/mods-available/security2.conf':
        ensure  => present,
        source  => 'puppet:///modules/profile/waf/apache2/security2.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['libapache2-mod-security2'],
    }

    httpd::site { 'modsecurity_administrative':
        priority => 00,
        content  => template('profile/waf/apache2/modsecurity_administrative.conf.erb'),
    }

    file { '/etc/apache2/administrative':
        ensure  => present,
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        content => secret('waf/administrative'),
        notify  => Service['apache2'],
    }

}
