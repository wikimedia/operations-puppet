# this class contains several resources that will conflict with other resources
# in the ldap module. Make sure to don't include this and the others
# at the same time. That's why there is an 'avoid confusion section'

class ldap::client::sssd(
    $ldapconfig,
) {
    # this provides the /etc/ldap.yaml file, which is used to
    # lookup for sshkeys. We could switch at some point to a native
    # sssd mechanism for that, but meanwhile...
    $yaml_data = {
        'servers'  => $ldapconfig['servernames'],
        'basedn'   => $ldapconfig['basedn'],
        'user'     => "cn=proxyagent,ou=profile,${ldapconfig['basedn']}",
        'password' => $ldapconfig['proxypass'],
    }
    file { '/etc/ldap.yaml':
        ensure  => file,
        content => to_yaml($yaml_data),
    }

    $packages_present = [
        'libpam-sss',
        'libnss-sss',
        'libsss-sudo',
        'sssd',
    ]

    $services = [
        'nss',
        'pam',
        'ssh',
        'sudo',
    ]

    # On bullseye, the services are started by socket, so there's no need to duplicate them in the sssd config itself.
    $socket_activation = debian::codename::ge('bullseye')

    if $socket_activation {
        $service_notify = ['sssd'] + $services.map |String $x| { "sssd-${x}" }
    } else {
        $service_notify = ['sssd']
    }

    # mkhomedir is not enabled automatically; activate it if needed
    exec { 'pam-auth-enable-mkhomedir':
        command => '/usr/sbin/pam-auth-update --force --enable mkhomedir',
        unless  => '/bin/grep pam_mkhomedir.so /etc/pam.d/common-session',
        require => Package['sssd', 'libpam-sss'],
    }

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
        notify  => Service[$service_notify],
        require => Package['sssd'],
    }

    if $socket_activation {
        $services.each |String $x| {
            # We declare these services to exist so that they can be restarted on config chagnes,
            # but not to start or be enabled as the socket units will take care of that during
            # normal operations.
            service { "sssd-${x}": }

            # And just to be sure, we ensure that the socket unit is enabled.
            service { "sssd-${x}.socket":
                enable => true,
            }
        }

        systemd::override { 'sssd-nss-auto-restart':
            unit   => 'sssd-nss.service',
            source => 'puppet:///modules/ldap/client/sssd/sssd-nss-auto-restart.override.service',
        }
    }

    service { 'sssd':
        ensure => 'running',
    }

    file { '/etc/ldap.conf':
        content => template('ldap/ldap.conf.erb'),
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
