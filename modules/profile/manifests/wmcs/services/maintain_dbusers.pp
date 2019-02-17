class profile::wmcs::services::maintain_dbusers(
    String $services_active_node = lookup('profile::wmcs::services::active_node'),
    String $labsdb_user = lookup('passwords::mysql::labsdb::user'),
    String $labsdb_password = lookup('passwords::mysql::labsdb::password'),
    String $labsdbaccounts_user = lookup('passwords::labsdbaccounts::db_user'),
    String $labsdbaccounts_password = lookup('passwords::labsdbaccounts::db_password'),
    $ldapconfig = hiera_hash('labsldapconfig'),
) {
    include passwords::mysql::labsdb
    include passwords::labsdbaccounts

    package { [
        'python3-ldap3',
        'python3-netifaces',
        'python3-systemd',
    ]:
        ensure => present,
    }

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
            'username' => $labsdb_user,
            'password' => $labsdb_password,
        },
        'accounts-backend' => {
            'host' => 'm5-master.eqiad.wmnet',
            'username' => $labsdbaccounts_user,
            'password' => $labsdbaccounts_password,
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

    $script = '/usr/local/sbin/wmcs-maintain-dbusers'

    #
    # the script expects the NFS data here.
    #
    $nfs_project = '/srv/tools/shared/tools/project'
    $nfs_home = '/srv/tools/shared/tools/home'
    file { [ '/srv/', '/srv/tools/', '/srv/tools/shared/', '/srv/tools/shared/tools/' ]:
        ensure => directory,
        before => [ File[$nfs_project], File[$nfs_home] ],
    }
    file { $nfs_project :
        ensure => link,
        target => '/mnt/nfs/labstore-secondary-tools-project',
        force  => true,
        before => File[$script],
    }
    file { $nfs_home :
        ensure => link,
        target => '/mnt/nfs/labstore-secondary-tools-home',
        force  => true,
        before => File[$script],
    }

    file { $script:
        source  => 'puppet:///modules/profile/wmcs/services/maintain_dbusers/wmcs-maintain-dbusers.py',
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        require => File['/etc/dbusers.yaml'],
        notify  => Systemd::Service['wmcs-maintain-dbusers'],
    }

    systemd::service { 'wmcs-maintain-dbusers':
        ensure         => present,
        content        => systemd_template('wmcs/services/wmcs-maintain-dbusers'),
        restart        => true,
        override       => false,
        require        => File[$script],
        service_params => {
            ensure     => ensure_service($::fqdn == $services_active_node),
        },
    }

    # TODO: now running on CloudVPS, not sure if this can work there
    #nrpe::monitor_systemd_unit_state { 'wncs-maintain-dbusers':
    #    description => 'Ensure mysql credential creation for tools users is running',
    #}
}
