class openstack::serverpackages::mitaka::stretch(
) {

    # hack, use the jessie-backports repository in stretch. This should work,
    # since jessie-backports packages are rebuilt from stretch anyway
    apt::repository { 'jessie-backports-for-mitaka-on-stretch':
        uri        => 'http://mirrors.wikimedia.org/debian/',
        dist       => 'jessie-backports',
        components => 'main',
    }

    # hack, use the jessie repository in stretch.
    apt::repository { 'jessie-for-mitaka-on-stretch':
        uri        => 'http://mirrors.wikimedia.org/debian/',
        dist       => 'jessie',
        components => 'main',
    }

    # make sure we don't have libssl1.0.0 installed, and exclude
    # packages that depend on it
    package { 'libssl1.0.0':
        ensure => 'absent',
    }

    apt::pin { 'mitaka_stretch_libpq5_nojessiebpo':
        package  => 'libpq5',
        pin      => 'version 9.6.6-0*',
        priority => '-1',
    }

    apt::pin { 'mitaka_stretch_libisns0_nojessiebpo':
        package  => 'libisns0',
        pin      => 'version 0.97-1*',
        priority => '-1',
    }
}
