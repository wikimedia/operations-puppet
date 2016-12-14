#
# Provides account services for labs user accounts,
# currently in the labstore module because we put these
# on the user's homedirs on NFS.
#
# Currently provides:
#   - MySQL replica / toolsdb accounts
#

class role::labs::db::maintain_dbusers {

    # We need a newer version of python3-ldap3 than what is in Jessie
    # For the connection time out / server pool features
    apt::pin { [
        'python3-ldap3',
        'python3-pyasn1',
    ]:
        pin      => 'release a=jessie-backports',
        priority => '1001',
        before   => Package['python3-ldap3'],
    }

    package { [
        'python3-ldap3',
        'python-yaml',
    ]:
        ensure => present,
    }

    $ldapconfig = hiera_hash('labsldapconfig', {})
    include passwords::mysql::labsdb
    include passwords::labsdbaccounts

    $creds = {
        'ldap' => {
            'hosts'    => [
                'ldap-labs.eqiad.wikimedia.org',
                'ldap-labs.codfw.wikimedia.org'
            ],
            'username' => 'cn=proxyagent,ou=profile,dc=wikimedia,dc=org',
            'password' => $ldapconfig['proxypass'],
        },
        'labsdbs' => {
            'hosts' => {
                'labsdb1001.eqiad.wmnet' => {
                    'grant-type' => 'legacy',
                },
                'labsdb1003.eqiad.wmnet' => {
                    'grant-type' => 'legacy',
                },
                'labsdb1005.eqiad.wmnet' => {
                    'grant-type' => 'legacy',
                },
                'labsdb1009.eqiad.wmnet' => {
                    'grant-type' => 'role',
                },
                'labsdb1010.eqiad.wmnet' => {
                    'grant-type' => 'role',
                },
                'labsdb1011.eqiad.wmnet' => {
                    'grant-type' => 'role',
                }
            },
            'username' => $::passwords::mysql::labsdb::user,
            'password' => $::passwords::mysql::labsdb::password,
        },
        'accounts-backend' => {
            'host' => 'm5-master.eqiad.wmnet',
            'username' => $::passwords::labsdbaccounts::db_user,
            'password' => $::passwords::labsdbaccounts::db_password,
        }
    }

    file { '/etc/dbusers.yaml':
        content => ordered_json($creds),
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        require => [
            Package['python3-ldap3'],
            Package['python-yaml'],
        ],
    }

    file { '/usr/local/sbin/maintain-dbusers':
        source  => 'puppet:///modules/role/labs/db/maintain-dbusers.py',
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        require => File['/etc/dbusers.yaml'],
        notify  => Base::Service_unit['maintain-dbusers'],
    }

    # To delete users from all the labsdb mysql databases
    file { '/usr/local/sbin/delete-dbuser':
        source => 'puppet:///modules/labstore/delete-dbuser',
        owner  => 'root',
        group  => 'root',
        mode   => '0550',
    }

    base::service_unit { 'maintain-dbusers':
        ensure        => present,
        systemd       => true,
        require       => File['/usr/local/sbin/maintain-dbusers'],
        template_name => 'labs/db/maintain-dbusers',
    }

    nrpe::monitor_systemd_unit_state { 'maintain-dbusers':
        description => 'Ensure mysql credential creation for tools users is running',
    }
}
