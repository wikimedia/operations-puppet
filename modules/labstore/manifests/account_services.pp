# == Class: labstore::account_services
# Provides account services for labs user accounts,
# currently in the labstore module because we put these
# on the user's homedirs on NFS.
#
# Currently provides:
#   - MySQL replica / toolsdb accounts
#
class labstore::account_services {

    require_package('python3-yaml', 'python3-ldap3')

    # Set to true only for the labstore that is currently
    # actively serving files
    $is_active = (hiera('active_labstore_host') == $::hostname)

    include passwords::ldap::labs
    include passwords::mysql::labsdb

    $creds = {
        'ldap' => {
            'host'     => 'ldap-labs.eqiad.wikimedia.org',
            'username' => 'cn=proxyagent,ou=profile,dc=wikimedia,dc=org',
            'password' => $::passwords::ldap::labs::proxypass,
        },
        'mysql' => {
            'hosts' => [
                'labsdb1001.eqiad.wmnet',
                'labsdb1002.eqiad.wmnet',
                'labsdb1003.eqiad.wmnet',
                'labsdb1005.eqiad.wmnet',
            ],
            'username' => $::passwords::mysql::labsdb::user,
            'password' => $::passwords::mysql::labsdb::password,
        }
    }

    file { '/etc/create-dbusers.yaml':
        content => ordered_json($creds),
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
    }

    file { '/usr/local/sbin/create-dbusers':
        source => 'puppet:///modules/labstore/create-dbusers',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    # To delete users from all the labsdb mysql databases
    file { '/usr/local/sbin/delete-dbuser':
        source => 'puppet:///modules/labstore/delete-dbuser',
        owner  => 'root',
        group  => 'root',
        mode   => '0550',
    }

    # Terrible hack
    if $is_active {
        $service_ensure = 'present'
    } else {
        $service_ensure = 'absent'
    }
    base::service_unit { 'create-dbusers':
        ensure  => $service_ensure,
        systemd => true,
    }

    if $is_active {
        nrpe::monitor_systemd_unit_state { 'create-dbusers':
            description => 'Ensure mysql credential creation for tools users is running',
        }
    }
}
