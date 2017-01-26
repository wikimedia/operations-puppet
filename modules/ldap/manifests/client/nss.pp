class ldap::client::nss(
    $ldapconfig = undef,
    $nsswitch_conf_source = 'puppet:///modules/ldap/nsswitch.conf',
) {

    require_package('libnss-ldapd', 'nss-updatedb', 'libnss-db', 'nscd', 'nslcd')

    package { [ 'libnss-ldap' ]:
        ensure => purged,
    }

    File {
        owner => 'root',
        group => 'root',
        mode  => '0444',
    }

    $nscd_conf = $::realm ? {
        'labs'  => 'puppet:///modules/ldap/nscd-labs.conf',
        default => 'puppet:///modules/ldap/nscd.conf',
    }

    file { '/etc/nscd.conf':
        require => Package['nscd'],
        notify  => Service['nscd'],
        source  => $nscd_conf,
    }

    file { '/etc/nsswitch.conf':
        notify => Service['nscd', 'nslcd'],
        source => $nsswitch_conf_source,
    }

    file { '/etc/ldap.conf':
        content => template('ldap/ldap.conf.erb'),
        require => File['/etc/nslcd.conf', '/etc/nscd.conf'],
        notify  => Service['nscd','nslcd'],
    }

    # So scripts don't have to parse the ldap.conf format
    include ::ldap::yamlcreds

    # Allow labs projects to give people custom shells
    $shell_override = hiera('user_login_shell', false)
    file { '/etc/nslcd.conf':
        content => template('ldap/nslcd.conf.erb'),
        mode    => '0440',
        require => Package['nslcd'],
        notify  => Service['nscd','nslcd'],
    }

    service { 'nscd':
        ensure    => running,
        subscribe => File['/etc/ldap/ldap.conf'],
        require   => Package['nscd'],
    }

    service { 'nslcd':
        ensure    => running,
        subscribe => File['/etc/ldap/ldap.conf'],
        require   => Package['nslcd'],
    }
}
