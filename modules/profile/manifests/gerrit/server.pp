# modules/profile/manifests/gerrit/server.pp
#
# filtertags: labs-project-git
class profile::gerrit::server(
    Stdlib::Ipv4 $ipv4 = lookup('gerrit::service::ipv4'),
    Stdlib::Fqdn $host = lookup('gerrit::server::host'),
    Array[Stdlib::Fqdn] $replica_hosts = lookup('gerrit::server::replica_hosts'),
    Boolean $backups_enabled = lookup('gerrit::server::backups_enabled'),
    String $backup_set = lookup('gerrit::server::backup_set'),
    Array[Stdlib::Fqdn] $gerrit_servers = lookup('gerrit::servers'),
    String $config = lookup('gerrit::server::config'),
    Boolean $use_acmechief = lookup('gerrit::server::use_acmechief'),
    Hash $ldap_config = lookup('ldap', Hash, hash, {}),
    Optional[Stdlib::Ipv6] $ipv6 = lookup('gerrit::service::ipv6'),
    Integer[8, 11] $java_version = lookup('gerrit::server::java_version'),
    Boolean $is_replica = lookup('gerrit::server::is_replica'),
    Optional[String] $scap_user = lookup('gerrit::server::scap_user'),
    Optional[String] $scap_key_name = lookup('gerrit::server::scap_key_name'),
    Optional[String] $db_user = lookup('gerrit::server::db_user'),
    Optional[String] $db_pass = lookup('gerrit::server::db_pass'),
    Boolean $enable_monitoring = lookup('gerrit::server::enable_monitoring', { default_value => true }),
) {

    interface::alias { 'gerrit server':
        ipv4 => $ipv4,
        ipv6 => $ipv6,
    }

    if !$is_replica and $enable_monitoring {
        monitoring::service { 'gerrit_ssh':
            description   => 'SSH access',
            check_command => "check_ssh_port_ip!29418!${ipv4}",
            contact_group => 'admins,gerrit',
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Gerrit',
        }
    }

    # ssh from users to gerrit
    ferm::service { 'gerrit_ssh_users':
        proto => 'tcp',
        port  => '29418',
    }

    # ssh between gerrit servers for cluster support
    $gerrit_servers_ferm=join($gerrit_servers, ' ')
    ferm::service { 'gerrit_ssh_cluster':
        port   => '22',
        proto  => 'tcp',
        srange => "(@resolve((${gerrit_servers_ferm})) @resolve((${gerrit_servers_ferm}), AAAA))",
    }

    ferm::service { 'gerrit_http':
        proto => 'tcp',
        port  => 'http',
    }

    ferm::service { 'gerrit_https':
        proto => 'tcp',
        port  => 'https',
    }

    if $backups_enabled and $backup_set != undef {
        backup::set { $backup_set:
            jobdefaults => "Hourly-${profile::backup::host::day}-${profile::backup::host::pool}"
        }
    }

    if $use_acmechief {
        class { '::sslcert::dhparam': }
        acme_chief::cert { 'gerrit':
            puppet_svc => 'apache2',
        }
    } else {
        if $is_replica {
            $tls_host = $replica_hosts[0]
        } else {
            $tls_host = $host
        }
        letsencrypt::cert::integrated { 'gerrit':
            subjects   => $tls_host,
            puppet_svc => 'apache2',
            system_svc => 'apache2',
        }
    }

    class { '::gerrit':
        host              => $host,
        ipv4              => $ipv4,
        ipv6              => $ipv6,
        replica           => $is_replica,
        replica_hosts     => $replica_hosts,
        config            => $config,
        use_acmechief     => $use_acmechief,
        ldap_config       => $ldap_config,
        java_version      => $java_version,
        scap_user         => $scap_user,
        scap_key_name     => $scap_key_name,
        db_user           => $db_user,
        db_pass           => $db_pass,
        enable_monitoring => $enable_monitoring
    }

    class { '::gerrit::replication_key':
        require => Class['gerrit'],
    }

    # Ship gerrit logs to ELK, everything should be in the JSON file now.
    # Just the sshd_log has a custom format.
    rsyslog::input::file { 'gerrit-json':
        path => '/var/log/gerrit/gerrit.json',
    }

    # Apache reverse proxies to jetty
    rsyslog::input::file { 'gerrit-apache2-error':
        path => '/var/log/apache2/*error*.log',
    }
    rsyslog::input::file { 'gerrit-apache2-access':
        path => '/var/log/apache2/*access*.log',
    }
}
