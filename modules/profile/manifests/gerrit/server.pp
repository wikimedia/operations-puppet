# modules/profile/manifests/gerrit/server.pp
#
# filtertags: labs-project-git
class profile::gerrit::server(
    Hash                              $ldap_config       = lookup('ldap', Hash, hash, {}),
    Stdlib::IP::Address::V4           $ipv4              = lookup('profile::gerrit::server::ipv4'),
    Optional[Stdlib::IP::Address::V6] $ipv6              = lookup('profile::gerrit::server::ipv6'),
    Stdlib::Fqdn                      $host              = lookup('profile::gerrit::server::host'),
    Boolean                           $backups_enabled   = lookup('profile::gerrit::server::backups_enabled'),
    String                            $backup_set        = lookup('profile::gerrit::server::backup_set'),
    Array[Stdlib::Fqdn]               $gerrit_servers    = lookup('profile::gerrit::server::servers'),
    String                            $config            = lookup('profile::gerrit::server::config'),
    Boolean                           $use_acmechief     = lookup('profile::gerrit::server::use_acmechief'),
    Integer[8, 11]                    $java_version      = lookup('profile::gerrit::server::java_version'),
    Boolean                           $is_replica        = lookup('profile::gerrit::server::is_replica'),
    Optional[Array[Stdlib::Fqdn]]     $replica_hosts     = lookup('profile::gerrit::server::replica_hosts'),
    Optional[String]                  $scap_user         = lookup('profile::gerrit::server::scap_user'),
    Optional[String]                  $scap_key_name     = lookup('profile::gerrit::server::scap_key_name'),
    Boolean                           $enable_monitoring = lookup('profile::gerrit::server::enable_monitoring'),
    Hash[String, Hash]                $replication       = lookup('profile::gerrit::server::replication'),
    String                            $ssh_host_key      = lookup('profile::gerrit::server::ssh_host_key'),
    Stdlib::Unixpath                  $git_dir           = lookup('profile::gerrit::server::git_dir'),
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
        class { 'sslcert::dhparam': }
        acme_chief::cert { 'gerrit':
            puppet_svc => 'apache2',
        }
    } else {
        ensure_packages('certbot')
        cron { 'certbot_renew':
            command => "/usr/bin/certbot -q renew --post-hook \"systemctl reload apache\" 2> /var/log/certbot.log",
            minute  => 4,
            hour    => 4,
            user    => 'root',
        }
    }

    class { 'gerrit':
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
        enable_monitoring => $enable_monitoring,
        replication       => $replication,
        ssh_host_key      => $ssh_host_key,
        git_dir           => $git_dir,
    }

    class { 'gerrit::replication_key':
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
