# this class contains several resources that will conflict with other resources
# in the ldap module. Make sure to don't include this and the others
# at the same time. That's why there is an 'avoid confusion section'

class ldap::client::sssd(
    $ldapconfig,
    $ldapincludes,
) {
    $packages_present = [
        'libpam-sss',
        'libnss-sss',
        'libsss-sudo',
        'sssd',
    ]

    package { $packages_present:
        ensure => 'present',
    }

    file { '/etc/nsswitch.conf':
        ensure  => 'present',
        content => file('ldap/nsswitch-sssd.conf'),
    }

    file { '/etc/sssd/sssd.conf':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0600',
        content => template('ldap/sssd.conf.erb'),
        notify  => Service['sssd'],
        require => Package['sssd'],
    }

    service { 'sssd':
        ensure  => 'running',
        require => [Package['sssd'], File['/etc/sssd/sssd.conf']],
    }

    #
    # start of avoid confusions section
    $packages_absent = [
        'nscd',
        'nslcd',
        'sudo-ldap',
    ]

    package { $packages_absent:
        ensure => 'absent',
    }

    $files_absent = [
        '/etc/nscd.conf',
        '/etc/nslcd.conf',
        '/etc/sudo-ldap.conf',
    ]

    file { $files_absent:
        ensure => 'absent',
    }
    # end of avoid confusions section
    #
}
