# modules/profile/manifests/gerrit/server.pp
#
class profile::gerrit(
    Hash                              $ldap_config       = lookup('ldap'),
    Stdlib::IP::Address::V4           $ipv4              = lookup('profile::gerrit::ipv4'),
    Optional[Stdlib::IP::Address::V6] $ipv6              = lookup('profile::gerrit::ipv6'),
    Boolean                           $bind_service_ip   = lookup('profile::gerrit::bind_service_ip'),
    Stdlib::Fqdn                      $host              = lookup('profile::gerrit::host'),
    Boolean                           $backups_enabled   = lookup('profile::gerrit::backups_enabled'),
    String                            $backup_set        = lookup('profile::gerrit::backup_set'),
    Array[Stdlib::Fqdn]               $ssh_allowed_hosts = lookup('profile::gerrit::ssh_allowed_hosts'),
    String                            $config            = lookup('profile::gerrit::config'),
    Boolean                           $use_acmechief     = lookup('profile::gerrit::use_acmechief'),
    Optional[Array[Stdlib::Fqdn]]     $replica_hosts     = lookup('profile::gerrit::replica_hosts'),
    Optional[String]                  $daemon_user       = lookup('profile::gerrit::daemon_user'),
    Stdlib::Unixpath                  $gerrit_site       = lookup('profile::gerrit::gerrit_site'),
    Optional[String]                  $scap_user         = lookup('profile::gerrit::scap_user'),
    Optional[Boolean]                 $manage_scap_user  = lookup('profile::gerrit::manage_scap_user'),
    Optional[String]                  $scap_key_name     = lookup('profile::gerrit::scap_key_name'),
    Boolean                           $enable_monitoring = lookup('profile::gerrit::enable_monitoring'),
    Hash[String, Hash]                $replication       = lookup('profile::gerrit::replication'),
    String                            $ssh_host_key      = lookup('profile::gerrit::ssh_host_key'),
    Stdlib::Unixpath                  $git_dir           = lookup('profile::gerrit::git_dir'),
    Stdlib::Unixpath                  $java_home         = lookup('profile::gerrit::java_home'),
    Boolean                           $mask_service      = lookup('profile::gerrit::mask_service'),
    Stdlib::Fqdn                      $active_host       = lookup('profile::gerrit::active_host'),
    Boolean                           $lfs_replica_sync  = lookup('profile::gerrit::lfs_replica_sync'),
    Optional[Array[Stdlib::Fqdn]]     $lfs_sync_dest     = lookup('profile::gerrit::lfs_sync_dest'),
) {
    require ::profile::java
    require ::passwords::gerrit

    $is_replica = $facts['fqdn'] != $active_host

    if $bind_service_ip {
        interface::alias { 'gerrit server':
            ipv4 => $ipv4,
            ipv6 => $ipv6,
        }
    }

    if !$is_replica and $enable_monitoring {
        prometheus::blackbox::check::tcp { 'gerrit-ssh':
            team     => 'collaboration-services-releng',
            severity => 'critical',
            port     => 29418,
        }
    }

    # ssh from users to gerrit
    firewall::service { 'gerrit_ssh_users':
        proto  => 'tcp',
        port   => 29418,
        drange => [$ipv4, $ipv6],
    }

    # ssh between gerrit servers for cluster support
    firewall::service { 'gerrit_ssh_cluster':
        port   => 22,
        proto  => 'tcp',
        srange => $ssh_allowed_hosts,
    }

    firewall::service { 'gerrit_http':
        proto  => 'tcp',
        port   => 80,
        drange => [$ipv4, $ipv6],
    }

    firewall::service { 'gerrit_https':
        proto  => 'tcp',
        port   => 443,
        drange => [$ipv4, $ipv6],
    }

    if $backups_enabled and $backup_set != undef {
        backup::set { $backup_set:
            jobdefaults => "Hourly-${profile::backup::host::day}-${profile::backup::host::pool}"
        }
        backup::set { 'home': }
    }

    if $use_acmechief {
        class { 'sslcert::dhparam': }
        acme_chief::cert { 'gerrit':
            puppet_svc => 'apache2',
        }
    } else {
        ensure_packages('certbot')
        systemd::timer::job { 'certbot-renew':
            ensure      => present,
            user        => 'root',
            description => 'renew TLS certificate using certbot',
            command     => "/usr/bin/certbot -q renew --post-hook \"systemctl reload apache\"",
            interval    => {'start' => 'OnCalendar', 'interval' => '*-*-* 04:04:00'},
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
        daemon_user       => $daemon_user,
        scap_user         => $scap_user,
        gerrit_site       => $gerrit_site,
        manage_scap_user  => $manage_scap_user,
        scap_key_name     => $scap_key_name,
        enable_monitoring => $enable_monitoring,
        replication       => $replication,
        ssh_host_key      => $ssh_host_key,
        git_dir           => $git_dir,
        java_home         => $java_home,
        mask_service      => $mask_service,
        active_host       => $active_host,
        lfs_replica_sync  => $lfs_replica_sync,
        lfs_sync_dest     => $lfs_sync_dest,
    }

    class { 'gerrit::replication_key':
        user    => $daemon_user,
        require => Class['gerrit'],
    }

    profile::gerrit::sshkey { 'gerrit.wikimedia.org':
        exported => true,
    }
    # Ship Gerrit built-in logs to ELK
    rsyslog::input::file { 'gerrit-json':
        path => '/var/log/gerrit/*_log.json',
    }

    # Apache reverse proxies to jetty
    rsyslog::input::file { 'gerrit-apache2-error':
        path => '/var/log/apache2/*error*.log',
    }
    rsyslog::input::file { 'gerrit-apache2-access':
        path => '/var/log/apache2/*access*.log',
    }
}
