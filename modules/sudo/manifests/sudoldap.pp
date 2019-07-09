class sudo::sudoldap
{
    # this cannot be used in Debian buster
    requires_os('debian < buster')

    # this assert is here only because it was before in the form of realm if branch.
    # This class only makes sense in CloudVPS anyway
    requires_realm('labs')

    # This hack is necessary because sudo-ldap can only be installed
    #  if SUDO_FORCE_REMOVE is set.  Puppet doesn't allow passing
    #  in an environment to a normal package resource.
    # Perhaps this is no longer required in modern Debian versions
    exec {'install sudo-ldap':
        command     => '/usr/bin/apt-get -q -y -o DPkg::Options::=--force-confold install sudo-ldap',
        environment => 'SUDO_FORCE_REMOVE=yes',
        onlyif      => '/usr/bin/apt-cache policy sudo-ldap | /bin/grep -q "Installed: (none)"',
    }

    package { 'sudo-ldap':
        ensure  => installed,
        require => Exec['install sudo-ldap'],
    }

    file { '/etc/sudoers':
        ensure  => present,
        mode    => '0440',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/sudo/sudoers',
        require => Package[sudo-ldap],
    }
}
