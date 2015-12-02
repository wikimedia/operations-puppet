# It is recommended that ldap::client::nss be included on systems that
# include ldap::client::utils, since some scripts use getent for ldap user info
# Remember though, that including ldap::client::nss will mean users in the
# ldap database will then be listed as users of the system, so use care.

class ldap::client::utils($ldapconfig) {
    package { [
        'python-ldap',
        'python-pycurl',
        'ldapvi',
    ]:
        ensure => latest,
    }

    file { '/usr/local/sbin/add-ldap-user':
        owner  => 'root',
        group  => 'root',
        mode   => '0544',
        source => 'puppet:///modules/ldap/scripts/add-ldap-user',
    }

    file { '/usr/local/sbin/add-labs-user':
        ensure => absent,
    }

    file { '/usr/local/sbin/modify-ldap-user':
        owner  => 'root',
        group  => 'root',
        mode   => '0544',
        source => 'puppet:///modules/ldap/scripts/modify-ldap-user',
    }

    file { '/usr/local/sbin/delete-ldap-user':
        owner  => 'root',
        group  => 'root',
        mode   => '0544',
        source => 'puppet:///modules/ldap/scripts/delete-ldap-user',
    }

    file { '/usr/local/sbin/add-ldap-group':
        owner  => 'root',
        group  => 'root',
        mode   => '0544',
        source => 'puppet:///modules/ldap/scripts/add-ldap-group',
    }

    file { '/usr/local/sbin/modify-ldap-group':
        owner  => 'root',
        group  => 'root',
        mode   => '0544',
        source => 'puppet:///modules/ldap/scripts/modify-ldap-group',
    }

    file { '/usr/local/sbin/delete-ldap-group':
        owner  => 'root',
        group  => 'root',
        mode   => '0544',
        source => 'puppet:///modules/ldap/scripts/delete-ldap-group',
    }

    file { '/usr/local/sbin/netgroup-mod':
        owner  => 'root',
        group  => 'root',
        mode   => '0544',
        source => 'puppet:///modules/ldap/scripts/netgroup-mod',
    }

    file { '/usr/local/sbin/ldaplist':
        ensure => link,
        target => '/usr/local/bin/ldaplist',
    }

    file { '/usr/local/bin/ldaplist':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/ldap/scripts/ldaplist',
    }

    if $::realm == 'labs' {
        # The 'ssh-key-ldap-lookup' tool is called during login ssh via AuthorizedKeysCommand.  It
        #  returns public keys from ldap for the specified username.
        # It is in /usr/sbin and not /usr/local/sbin because on Debian /usr/local is 0775
        # and sshd refuses to use anything under /usr/local because of the permissive group
        # permission there (and group is set to 'staff', slightly different from root).
        # https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=538392
        file { '/usr/sbin/ssh-key-ldap-lookup':
            owner  => 'root',
            group  => 'root',
            mode   => '0555',
            source => 'puppet:///modules/ldap/scripts/ssh-key-ldap-lookup',
        }
        # For security purposes, sshd will only run ssh-key-ldap-lookup as the 'ssh-key-ldap-lookup' user.
        user { 'ssh-key-ldap-lookup':
            ensure => present,
            system => true,
        }
    }

    file { '/usr/local/sbin/change-ldap-passwd':
        owner  => 'root',
        group  => 'root',
        mode   => '0544',
        source => 'puppet:///modules/ldap/scripts/change-ldap-passwd',
    }

    file { '/usr/local/sbin/homedirectorymanager.py':
        owner  => 'root',
        group  => 'root',
        mode   => '0544',
        source => 'puppet:///modules/ldap/scripts/homedirectorymanager.py',
    }

    file { '/usr/local/lib/python2.7/dist-packages/ldapsupportlib.py':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/ldap/scripts/ldapsupportlib.py',
    }

    file { '/etc/ldap/scriptconfig.py':
        ensure => absent,
    }

    if ( $::realm != 'labs' ) {
        file { '/etc/ldap/.ldapscriptrc':
            owner   => 'root',
            group   => 'root',
            mode    => '0700',
            content => template('ldap/ldapscriptrc.erb'),
        }
    }
}

