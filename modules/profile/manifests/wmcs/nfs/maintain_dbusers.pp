#
# Provides account services for labs user accounts,
# currently in the labstore module because we put these
# on the user's homedirs on NFS.
#
# Currently provides:
#   - MySQL replica / toolsdb accounts
#

class profile::wmcs::nfs::maintain_dbusers (
    Hash                    $ldapconfig             = lookup('labsldapconfig', {'merge' => hash}),
    Hash                    $production_ldap_config = lookup('ldap', {'merge' => hash}),
    Stdlib::IP::Address::V4 $cluster_ip             = lookup('profile::wmcs::nfs::primary::cluster_ip'),
    Hash[String,Stdlib::Port] $section_ports        = lookup('profile::mariadb::section_ports'),
    Hash[String,Integer]    $variances              = lookup('profile::wmcs::nfs::primary::mysql_variances'),
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

    $multiinstance_collected = $section_ports.keys.reduce({}) |$memo, $section|{
        $memo + {
            $section =>  query_nodes(
                "(Class['role::wmcs::db::wikireplicas::web_multiinstance'] or Class['role::wmcs::db::wikireplicas::analytics_multiinstance']) and Profile::Mariadb::Section[${section}]"
            )
        }
    }
    $multiinstance_filtered = $multiinstance_collected.filter | $section, $hosts | {
        !empty($hosts)
    }

    $multiinstance_connect_addresses = $multiinstance_filtered.map |$section, $hosts| {
        $hosts.map | $host | {
            "${host}:${section_ports[$section]}"
        }
    }

    $legacy_hosts = {
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
    }

    if !empty($multiinstance_connect_addresses) {
        $multiinstance_hosts = $multiinstance_connect_addresses.flatten().unique().reduce({}) | $memo, $conn_str | {
            $memo + {$conn_str => {'grant-type' => 'role'}}
        }
        $all_hosts = $legacy_hosts + $multiinstance_hosts
    } else {
        $all_hosts = $legacy_hosts
    }

    $creds = {
        'ldap' => {
            'hosts'    => [
                $production_ldap_config['ro-server'],
                $production_ldap_config['ro-server-fallback'],
            ],
            'username' => 'cn=proxyagent,ou=profile,dc=wikimedia,dc=org',
            'password' => $ldapconfig['proxypass'],
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
        'nfs-cluster-ip'   => $cluster_ip,
        'variances'        => $variances,
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
