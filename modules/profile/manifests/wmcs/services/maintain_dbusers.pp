# SPDX-License-Identifier: Apache-2.0
#
# Provides account services for tools/paws user accounts.
# This is the client side working from cloudcontrols, it needs a server side on each NFS server to
# create the credentials in the user homes.
#

class profile::wmcs::services::maintain_dbusers (
    Hash                                                    $labsldapconfig               = lookup('labsldapconfig', {'merge' => hash}),
    Hash                                                    $ldap                         = lookup('ldap', {'merge' => hash}),
    Hash[Profile::Mariadb::Valid_section, Stdlib::Port]     $section_ports                = lookup('profile::mariadb::section_ports'),
    Hash[String[1], Hash[Enum['max_connections'], Integer]] $mysql_variances              = lookup('profile::wmcs::services::maintain_dbusers::mysql_variances'),
    String[1]                                               $paws_replica_cnf_user        = lookup('profile::wmcs::services::maintain_dbusers::paws_replica_cnf_user'),
    String[1]                                               $paws_replica_cnf_htpassword  = lookup('profile::wmcs::services::maintain_dbusers::paws_replica_cnf_htpassword'),
    String[1]                                               $paws_replica_cnf_root_url    = lookup('profile::wmcs::services::maintain_dbusers::paws_replica_cnf_root_url'),
    String[1]                                               $tools_replica_cnf_user       = lookup('profile::wmcs::services::maintain_dbusers::tools_replica_cnf_user'),
    String[1]                                               $tools_replica_cnf_htpassword = lookup('profile::wmcs::services::maintain_dbusers::tools_replica_cnf_htpassword'),
    String[1]                                               $tools_replica_cnf_root_url   = lookup('profile::wmcs::services::maintain_dbusers::tools_replica_cnf_root_url'),
    String[1]                                               $maintain_dbusers_primary     = lookup('wmcs_maintain_dbusers_primary'),
){
    ensure_packages([
        'python3-ldap3',
        'python3-prometheus-client',
    ])

    include passwords::mysql::labsdb
    include passwords::labsdbaccounts

    $multiinstance_connect_addresses = $section_ports.keys.reduce({}) |$memo, $section| {
        $pql = @("QUERY")
        nodes[certname] {
            resources {
                type = "Class" and title in [
                    'Role::Wmcs::Db::Wikireplicas::Web_multiinstance',
                    'Role::Wmcs::Db::Wikireplicas::Analytics_multiinstance',
                    'Role::Wmcs::Db::Wikireplicas::Dedicated::Analytics_multiinstance'

                ]
            } and resources { type = 'Profile::Mariadb::Section' and title = "${section}" }
        }
        |QUERY
        $memo + {
            $section => wmflib::puppetdb_query($pql).map |$resource| { $resource['certname'] }
        }
    }.filter | $section, $hosts | { !$hosts.empty }.map |$section, $hosts| {
        $hosts.map |$host| {
            "${host}:${section_ports[$section]}"
        }
    }.flatten.unique

    $legacy_hosts = {
        'tools.db.svc.wikimedia.cloud:3306' => {
            'grant-type' => 'legacy',
        },
    }

    if !empty($multiinstance_connect_addresses) {
        $multiinstance_hosts = $multiinstance_connect_addresses.reduce({}) | $memo, $conn_str | {
            $memo + {$conn_str => {'grant-type' => 'role'}}
        }
        $all_hosts = $legacy_hosts + $multiinstance_hosts
    } else {
        $all_hosts = $legacy_hosts
    }

    $creds = {
        'ldap' => {
            'hosts'    => [
                $ldap['ro-server'],
                $ldap['ro-server-fallback'],
            ],
            'username' => 'cn=proxyagent,ou=profile,dc=wikimedia,dc=org',
            'password' => $labsldapconfig['proxypass'],
        },
        'labsdbs' => {
            'hosts'    => $all_hosts,
            'username' => $::passwords::mysql::labsdb::user,
            'password' => $::passwords::mysql::labsdb::password,
        },
        'accounts-backend' => {
            'host' => 'm5-master.eqiad.wmnet',
            'username' => $::passwords::labsdbaccounts::db_user,
            'password' => $::passwords::labsdbaccounts::db_password,
        },
        'replica_cnf' => {
            'paws'  => {
                'root_url' => $paws_replica_cnf_root_url,
                'username' => $paws_replica_cnf_user,
                'password' => $paws_replica_cnf_htpassword,
            },
            'tools' => {
                'root_url' => $tools_replica_cnf_root_url,
                'username' => $tools_replica_cnf_user,
                'password' => $tools_replica_cnf_htpassword,
            },
        },
        'variances'        => $mysql_variances,
    }

    file { '/etc/dbusers.yaml':
        content => to_yaml($creds),
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
        notify  => Service['maintain-dbusers'],
    }

    file { '/usr/local/sbin/maintain-dbusers':
        source  => 'puppet:///modules/profile/wmcs/services/maintain_dbusers/maintain_dbusers.py',
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        require => File['/etc/dbusers.yaml'],
        notify  => Service['maintain-dbusers'],
    }

    systemd::service { 'maintain-dbusers':
        ensure  => stdlib::ensure($facts['networking']['fqdn'] == $maintain_dbusers_primary),
        content => systemd_template('wmcs/services/maintain-dbusers'),
        restart => true,
    }
}
