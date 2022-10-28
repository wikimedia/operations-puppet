# It is recommended that ldap::client::nss be included on systems that
# include ldap::client::utils, since some scripts use getent for ldap user info
# Remember though, that including ldap::client::nss will mean users in the
# ldap database will then be listed as users of the system, so use care.

class ldap::client::utils($ldapconfig) {

    # No python2 on Bullseye or later
    if debian::codename::le('buster') {
        ensure_packages(['python-pycurl', 'python-pyldap'])
    }
    ensure_packages(['python3-pycurl', 'python3-pyldap'])

    file { '/usr/local/sbin/add-ldap-group':
        owner  => 'root',
        group  => 'root',
        mode   => '0544',
        source => 'puppet:///modules/ldap/scripts/add-ldap-group.py',
    }

    file { '/usr/local/sbin/ldaplist':
        ensure => link,
        target => '/usr/local/bin/ldaplist',
    }

    file { '/usr/local/bin/ldaplist':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/ldap/scripts/ldaplist.py',
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
            source => 'puppet:///modules/ldap/scripts/ssh-key-ldap-lookup.py',
        }

        # For security purposes, sshd will only run ssh-key-ldap-lookup as the 'ssh-key-ldap-lookup' user.
        user { 'ssh-key-ldap-lookup':
            ensure => present,
            system => true,
            home   => '/nonexistent', # Since things seem to check for $HOME/.whatever unconditionally...
            shell  => '/bin/false',
        }
    }
    $python3_version = debian::codename() ? {
        'stretch'  => '3.5',
        'buster'   => '3.7',
        'bullseye' => '3.9',
        default    => '3.7',
    }

    file { "/usr/local/lib/python${python3_version}/dist-packages/ldapsupportlib.py":
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/ldap/scripts/ldapsupportlib.py',
    }

    if debian::codename::le('buster') {
        file { '/usr/local/lib/python2.7/dist-packages/ldapsupportlib.py':
            owner  => 'root',
            group  => 'root',
            mode   => '0444',
            source => 'puppet:///modules/ldap/scripts/ldapsupportlib.py',
        }
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

