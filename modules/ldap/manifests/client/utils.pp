# It is recommended that ldap::client::nss be included on systems that
# include ldap::client::utils, since some scripts use getent for ldap user info
# Remember though, that including ldap::client::nss will mean users in the
# ldap database will then be listed as users of the system, so use care.

class ldap::client::utils() {
    if $::realm == 'labs' {
        ensure_packages('python3-ldap')

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
}
