
class profile::waf::apache2::administrative {

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

    httpd::conf { 'modsecurity_admin':
        priority => 00,
        content  => secret('waf/modsecurity_admin.conf'),
    }

    file { '/etc/apache2/admin1':
        ensure  => present,
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        content => secret('waf/admin1'),
        notify  => Service['apache2'],
    }
    file { '/etc/apache2/admin2':
        ensure  => present,
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        content => secret('waf/admin2'),
        notify  => Service['apache2'],
    }
    file { '/etc/apache2/admin3':
        ensure  => present,
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        content => secret('waf/admin3'),
        notify  => Service['apache2'],
    }
}
