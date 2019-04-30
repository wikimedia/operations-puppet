class sudo {

    if $::realm == labs {
        $package = 'sudo-ldap'

        # This hack is necessary because sudo-ldap can only be installed
        #  if SUDO_FORCE_REMOVE is set.  Puppet doesn't allow passing
        #  in an environment to a normal package resource.
        exec {'install sudo-ldap':
            command     => '/usr/bin/apt-get -q -y -o DPkg::Options::=--force-confold install sudo-ldap',
            environment => 'SUDO_FORCE_REMOVE=yes',
            onlyif      => '/usr/bin/apt-cache policy sudo-ldap | /bin/grep -q "Installed: (none)"',
        }

        package { $package:
            ensure  => installed,
            require => Exec['install sudo-ldap'],
        }
    } else {
        $package = 'sudo'

        package { $package:
            ensure => installed,
        }
    }



    file { '/etc/sudoers':
        ensure  => present,
        mode    => '0440',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/sudo/sudoers',
        require => Package[$package],
    }
}
