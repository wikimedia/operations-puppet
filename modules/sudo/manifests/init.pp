class sudo {
    $package = $::realm ? {
        'labs'  => 'sudo-ldap',
        default => 'sudo',
    }

    package { $package:
        ensure => installed,
    }
}
