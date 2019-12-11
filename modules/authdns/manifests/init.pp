# == Class authdns
# A class to implement Wikimedia's authoritative DNS system
#
class authdns {
    # The package would create this as well if missing, but this allows
    # puppetization to create directories and files owned by these before the
    # package is even installed...
    group { 'gdnsd':
        ensure => present,
        system => true,
    }
    user { 'gdnsd':
        ensure     => present,
        gid        => 'gdnsd',
        shell      => '/bin/false',
        comment    => '',
        home       => '/var/run/gdnsd',
        managehome => false,
        system     => true,
        require    => Group['gdnsd'],
    }

    package { 'gdnsd':
        ensure => installed,
    }

    # Ensure that 'restarts' are converted to seamless reloads; it never needs
    # a true restart under any remotely normal conditions.
    service { 'gdnsd':
        ensure     => 'running',
        hasrestart => true,
        hasstatus  => true,
        restart    => 'service gdnsd reload',
        require    => Package['gdnsd'],
    }
}
