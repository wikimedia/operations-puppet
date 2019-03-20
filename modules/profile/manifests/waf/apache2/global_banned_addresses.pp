
class profile::waf::apache2::global_banned_addresses {

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

    httpd::site { 'modsecurity_global_ipaddress_banlist':
        priority => 00,
        content  => template('profile/waf/apache2/modsecurity_global_ipaddress_banlist.conf.erb'),
    }

    file { '/etc/apache2/global_ipaddress_banlist':
        ensure  => present,
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        content => secret('waf/global_ipaddress_banlist');
    }

}
