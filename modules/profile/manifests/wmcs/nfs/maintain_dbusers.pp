#
# Provides account services for labs user accounts,
# currently in the labstore module because we put these
# on the user's homedirs on NFS.
#
# Currently provides:
#   - MySQL replica / toolsdb accounts
#

class profile::wmcs::nfs::maintain_dbusers (
    $ldapconfig = lookup('labsldapconfig', {merge => hash, default => {}})
){

    package { [
        'python3-ldap3',
        'python3-netifaces',
        'python3-systemd',
    ]:
        ensure => present,
    }

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
                '172.16.7.153' => {
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
                },
            },
            'username' => $::passwords::mysql::labsdb::user,
            'password' => $::passwords::mysql::labsdb::password,
        },
        'accounts-backend' => {
            'host' => 'm5-master.eqiad.wmnet',
            'username' => $::passwords::labsdbaccounts::db_user,
            'password' => $::passwords::labsdbaccounts::db_password,
        },
        # Pick this up from Hiera once it gets put into hiera
        # in role::labs::nfs::secondary
        'nfs-cluster-ip'   => '10.64.37.18',
    }

    file { '/etc/dbusers.yaml':
        content => ordered_yaml($creds),
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
    }

    file { '/usr/local/sbin/maintain-dbusers':
        source  => 'puppet:///modules/profile/wmcs/nfs/maintain-dbusers.py',
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        require => File['/etc/dbusers.yaml'],
        notify  => Systemd::Service['maintain-dbusers'],
    }

    systemd::service { 'maintain-dbusers':
        ensure  => present,
        content => systemd_template('wmcs/nfs/maintain-dbusers'),
        restart => true,
    }

    nrpe::monitor_systemd_unit_state { 'maintain-dbusers':
        description => 'Ensure mysql credential creation for tools users is running',
    }
}
