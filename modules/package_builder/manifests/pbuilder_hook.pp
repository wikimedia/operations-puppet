# Definition pbuilder_hook
define package_builder::pbuilder_hook(
    String $distribution='bullseye',
    String $components='main',
    Stdlib::Httpurl $mirror='http://apt.wikimedia.org/wikimedia',
    Stdlib::Httpurl $upstream_mirror='http://mirrors.wikimedia.org/debian',
    Stdlib::Unixpath $basepath='/var/cache/pbuilder',
) {
    file { "${basepath}/hooks/${distribution}":
        ensure  => directory,
        mode    => '0755',
        recurse => true,
        purge   => true,
    }

    file { "${basepath}/hooks/${distribution}/C10shell.wikimedia.org":
        ensure  => present,
        mode    => '0555',
        content => template('package_builder/C10shell.wikimedia.org.erb'),
    }

    if $distribution == 'bookworm' {
        file { "${basepath}/hooks/${distribution}/D04java8-bookworm":
            ensure => present,
            mode   => '0555',
            source => 'puppet:///modules/package_builder/hooks/D04java8-bookworm',
        }

        file { "${basepath}/hooks/${distribution}/D04maps":
            ensure => present,
            mode   => '0555',
            source => 'puppet:///modules/package_builder/hooks/D04maps',
        }
    }

    if $distribution == 'bullseye' {
        # add a hook for building packages against backported pybal stack
        file { "${basepath}/hooks/${distribution}/D04pybal":
            ensure => present,
            mode   => '0555',
            source => 'puppet:///modules/package_builder/hooks/D04pybal',
        }
    }

    if $distribution != 'sid' {
        if $distribution == 'bullseye' or $distribution == 'bookworm' {
            file { "${basepath}/hooks/${distribution}/D01apt.wikimedia.org":
                ensure  => present,
                mode    => '0555',
                content => template('package_builder/D01apt.wikimedia.org.erb'),
            }
        } else { # Starting with Trixie, apt-key is no longer around and we need signed-by
            file { "${basepath}/hooks/${distribution}/D01apt.wikimedia.org":
                ensure  => present,
                mode    => '0555',
                content => template('package_builder/D01apt.wikimedia.org-trixie.erb'),
            }
        }

        file { "${basepath}/hooks/${distribution}/D01security":
            ensure  => present,
            mode    => '0555',
            content => template('package_builder/D01security.erb'),
        }

        file { "${basepath}/hooks/${distribution}/D02backports":
            ensure  => present,
            mode    => '0555',
            content => template('package_builder/D02backports.erb'),
        }
    }

    file { "${basepath}/hooks/${distribution}/D05localsources":
        ensure  => present,
        mode    => '0555',
        content => template('package_builder/D05localsources.erb'),
    }

    ['72', '74', '81', '83'].each|String $php_version| {
        file { "${basepath}/hooks/${distribution}/D04php${php_version}":
            ensure  => present,
            mode    => '0555',
            content => template('package_builder/D04php.erb'),
        }
    }

    # add a hook for building JDK 8 forward port dependencies from a dedicated component
    file { "${basepath}/hooks/${distribution}/D04java8":
        ensure => present,
        mode   => '0555',
        source => 'puppet:///modules/package_builder/hooks/D04java8'
    }

    # on bookworm, add a hook for building haproxy with some dependencies in a dedicated component
    if $distribution == 'bookworm' {
        file { "${basepath}/hooks/${distribution}/D04haproxy26":
            ensure => present,
            mode   => '0555',
            source => 'puppet:///modules/package_builder/hooks/D04haproxy26'
        }
    }

    file { "${basepath}/hooks/${distribution}/D04java21":
        ensure => present,
        mode   => '0555',
        source => 'puppet:///modules/package_builder/hooks/D04java21'
    }

    file { "${basepath}/hooks/${distribution}/D04ech":
        ensure => present,
        mode   => '0555',
        source => 'puppet:///modules/package_builder/hooks/D04ech'
    }

    file { "${basepath}/hooks/${distribution}/D04component":
      ensure  => file,
      mode    => '0555',
      content => template('package_builder/D04component.erb'),
    }

    # Disable rebuilding man-db (T276632)
    file { "${basepath}/hooks/${distribution}/D80no-man-db-rebuild":
      ensure => present,
      mode   => '0555',
      source => 'puppet:///modules/package_builder/hooks/D80no-man-db-rebuild'
    }
}
