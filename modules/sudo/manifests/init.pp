class sudo {
    $package = $::realm ? {
        'labs'  => 'sudo-ldap',
        default => 'sudo',
    }

    package { $package:
        ensure => installed,
    }

    file { '/etc/sudoers':
        ensure  => present,
        mode    => '0440',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/sudo/sudoers',
        require => Package[$package],
    }

    file { '/etc/sudoers.d':
        ensure  => directory,
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
        recurse => true,
        purge   => true,
        require => Package[$package],
    }
}
