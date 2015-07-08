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

    include passwords::mysql::labsdb

    $creds = {
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
        mode    => '0444',
    }

    file { '/usr/local/bin/create-dbusers':
        source => 'puppet:///modules/labstore/create-dbusers',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }
}
