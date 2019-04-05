class openstack::serverpackages::mitaka::stretch(
) {

    # hack, use the jessie-backports repository in stretch. This should work,
    # since jessie-backports packages are rebuilt from stretch anyway
    require openstack::commonpackages::mitaka

    # make sure we don't have libssl1.0.0 installed, and exclude
    # packages that depend on it
    package { 'libssl1.0.0':
        ensure => 'absent',
    }

    # in stretch, these packages are included in both our custom repo component
    # and in the stretch stable repo. Avoid conflicts with apt by avoiding
    # installing the version from our custom repo.
    $avoid_packages = [
        'python-cryptography',
        'libpq5',
        'libisns0',
        'libjs-sphinxdoc',
        'python-sphinx',
        'sphinx-common',
        'sqlite3',
        'pdns-recursor',
    ]

    $avoid_packages_list = join($avoid_packages, ' ')
    apt::pin { 'mitaka_stretch_nojessiebpo':
        package  => $avoid_packages_list,
        pin      => 'release c=openstack-mitaka-jessie',
        priority => '-1',
    }

    #
    # puppet cleanup, remove after a couple of cycles
    #
    apt::pin { 'mitaka_stretch_python-cryptography_nojessiebpo':
        ensure   => 'absent',
        package  => 'python-cryptography',
        pin      => 'version 1.7.1-3~bpo9*',
        priority => '-1',
    }

    apt::pin { 'mitaka_stretch_libpq5_nojessiebpo':
        ensure   => 'absent',
        package  => 'libpq5',
        pin      => 'version 9.6.6-0*',
        priority => '-1',
    }

    apt::pin { 'mitaka_stretch_libisns0_nojessiebpo':
        ensure   => 'absent',
        package  => 'libisns0',
        pin      => 'version 0.97-1*',
        priority => '-1',
    }

    apt::pin { 'mitaka_stretch_libjs-sphinxdoc_nojessiebpo':
        ensure   => 'absent',
        package  => 'libjs-sphinxdoc',
        pin      => 'version 1.4.9-2~bpo8+1',
        priority => '-1',
    }

    apt::pin { 'mitaka_stretch_python-sphinx_nojessiebpo':
        ensure   => 'absent',
        package  => 'python-sphinx',
        pin      => 'version 1.4.9-2~bpo8+1',
        priority => '-1',
    }

    apt::pin { 'mitaka_stretch_sqlite3_nojessiebpo':
        ensure   => 'absent',
        package  => 'sqlite3',
        pin      => 'version 3.16.2-3~bpo8+1',
        priority => '-1',
    }
}
