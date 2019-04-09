# this class contains several resources that will conflict with other resources
# defined in the ldap::client:sssd module, since is intended to wipe that class
class ldap::client::nosssd
{
    $packages_absent = [
        'libpam-sss',
        'libnss-sss',
        'sssd',
    ]

    package { $packages_absent:
        ensure => 'absent',
    }

    file { '/etc/sssd/sssd.conf':
        ensure => 'absent',
    }
}
