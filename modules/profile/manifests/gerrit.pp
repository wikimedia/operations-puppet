# modules/profile/manifests/gerrit/server.pp
#
class profile::gerrit(
    Hash                              $ldap_config                  = lookup('ldap'),
    Stdlib::IP::Address::V4           $ipv4                         = lookup('profile::gerrit::ipv4'),
    Optional[Stdlib::IP::Address::V6] $ipv6                         = lookup('profile::gerrit::ipv6'),
    Boolean                           $bind_service_ip              = lookup('profile::gerrit::bind_service_ip'),
    Stdlib::Fqdn                      $host                         = lookup('profile::gerrit::host'),
    Boolean                           $backups_enabled              = lookup('profile::gerrit::backups_enabled'),
    String                            $backup_set                   = lookup('profile::gerrit::backup_set'),
    Array[Stdlib::Fqdn]               $ssh_allowed_hosts            = lookup('profile::gerrit::ssh_allowed_hosts'),
    String                            $config                       = lookup('profile::gerrit::config'),
    Boolean                           $use_acmechief                = lookup('profile::gerrit::use_acmechief'),
    Optional[Array[Stdlib::Fqdn]]     $replica_hosts                = lookup('profile::gerrit::replica_hosts'),
    Optional[Array[Stdlib::Fqdn]]     $spare_hosts                  = lookup('profile::gerrit::spare_hosts'),
    Optional[String]                  $daemon_user                  = lookup('profile::gerrit::daemon_user'),
    Optional[Stdlib::Unixpath]        $daemon_user_dir              = lookup('profile::gerrit::daemon_user_dir', {default_value => '/var/lib/gerrit'}),
    Stdlib::Unixpath                  $gerrit_site                  = lookup('profile::gerrit::gerrit_site'),
    Optional[String]                  $scap_user                    = lookup('profile::gerrit::scap_user'),
    Optional[Boolean]                 $manage_scap_user             = lookup('profile::gerrit::manage_scap_user'),
    Optional[String]                  $scap_key_name                = lookup('profile::gerrit::scap_key_name'),
    Boolean                           $enable_monitoring            = lookup('profile::gerrit::enable_monitoring'),
    Hash[String, Hash]                $replication                  = lookup('profile::gerrit::replication'),
    Boolean                           $spare_replication_enabled    = lookup('profile::gerrit::spare_replication_enabled', { 'default_value' => true }),
    Array[String]                     $ssh_host_keys                = lookup('profile::gerrit::ssh_host_keys'),
    String                            $service_account              = lookup('profile::gerrit::service_account', { 'default_value' => 'gerrit2' }),
    Stdlib::Unixpath                  $git_dir                      = lookup('profile::gerrit::git_dir'),
    Stdlib::Unixpath                  $java_home                    = lookup('profile::gerrit::java_home'),
    Boolean                           $mask_service                 = lookup('profile::gerrit::mask_service'),
    Stdlib::Fqdn                      $active_host                  = lookup('profile::gerrit::active_host'),
    Stdlib::Fqdn                      $spare_host                   = lookup('profile::gerrit::spare_host'),
    Stdlib::Fqdn                      $replica_host                 = lookup('profile::gerrit::replica_host'),
    Boolean                           $lfs_replica_sync             = lookup('profile::gerrit::lfs_replica_sync'),
    Optional[Array[Stdlib::Fqdn]]     $lfs_sync_dest                = lookup('profile::gerrit::lfs_sync_dest'),
) {
    require ::profile::java
    require ::passwords::gerrit

    $fqdn       = $facts['networking']['fqdn']
    $is_replica = $fqdn != $active_host

    $rename_project_urls = $spare_replication_enabled ? {
        true    => [
            "ssh://${service_account}@${replica_host}:29418",
            "ssh://${service_account}@${spare_host}:29418",
        ],
        default => [
            "ssh://${service_account}@${replica_host}:29418",
        ],
    }

    $repl_base = deep_merge($replication, {
            'replica' => {
                'url' => "${daemon_user}@${replica_host}:/srv/gerrit/git/\${name}.git",
            },
    })

    $repl = $spare_replication_enabled ? {
        true    => deep_merge($repl_base, {
            'spare' => {
                'url' => "${daemon_user}@${spare_host}:/srv/gerrit/git/\${name}.git",
            },
        }),
        default => $repl_base.filter |$k, $v| { $k != 'spare' },
    }

    $local_lfs_replica_sync = ($fqdn == $spare_host and !$spare_replication_enabled) ? {
        true    => false,
        default => $lfs_replica_sync,
    }

    $local_lfs_sync_dest = $lfs_sync_dest ? {
        undef   => undef,
        default => $spare_replication_enabled ? {
            true    => $lfs_sync_dest,
            default => $lfs_sync_dest.filter |$h| { $h != $spare_host },
        },
    }

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

    # ssh from production networks (tcp proxies) to gerrit
    firewall::service { 'gerrit_ssh_cdn':
        proto    => 'tcp',
        port     => 29418,
        src_sets => ['PRODUCTION_NETWORKS'],
    }

    # ssh between gerrit servers for cluster support
    firewall::service { 'gerrit_ssh_cluster':
        port   => 22,
        proto  => 'tcp',
        srange => $ssh_allowed_hosts,
    }

    # caches for access from CDN
    # bastion access for tunnelencabulator for emergencies
    # deployment and cumin hosts for running tests
    firewall::service { 'gerrit_http':
        proto    => 'tcp',
        port     => 80,
        drange   => [$ipv4, $ipv6],
        src_sets => ['CACHES', 'BASTION_HOSTS', 'DEPLOYMENT_HOSTS', 'CUMIN_MASTERS'],
    }

    # caches for access from CDN
    # bastion access for tunnelencabulator for emergencies
    # deployment and cumin hosts for running tests.
    firewall::service { 'gerrit_https':
        proto    => 'tcp',
        port     => 443,
        drange   => [$ipv4, $ipv6, $facts['networking']['ip'], $facts['networking']['ip6']],
        src_sets => ['CACHES', 'BASTION_HOSTS', 'DEPLOYMENT_HOSTS', 'CUMIN_MASTERS'],
    }

    if $backups_enabled and $backup_set != undef {
        backup::set { $backup_set:
            jobdefaults => 'Hourly-Tue-ReposEqiad',
        }
        backup::set { 'home':
            jobdefaults => 'Monthly-1st-Mon-ReposEqiad',
        }
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
        host                => $host,
        ipv4                => $ipv4,
        ipv6                => $ipv6,
        replica             => $is_replica,
        replica_hosts       => $replica_hosts,
        spare_hosts         => $spare_hosts,
        config              => $config,
        use_acmechief       => $use_acmechief,
        ldap_config         => $ldap_config,
        daemon_user         => $daemon_user,
        daemon_user_dir     => $daemon_user_dir,
        scap_user           => $scap_user,
        gerrit_site         => $gerrit_site,
        manage_scap_user    => $manage_scap_user,
        scap_key_name       => $scap_key_name,
        enable_monitoring   => $enable_monitoring,
        replication         => $repl,
        ssh_host_keys       => $ssh_host_keys,
        git_dir             => $git_dir,
        java_home           => $java_home,
        mask_service        => $mask_service,
        active_host         => $active_host,
        lfs_replica_sync    => $local_lfs_replica_sync,
        lfs_sync_dest       => $local_lfs_sync_dest,
        replica_host        => $replica_host,
        spare_host          => $spare_host,
        rename_project_urls => $rename_project_urls,
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
        path => "${gerrit_site}/logs/*_log.json",
    }

    # Apache reverse proxies to jetty
    rsyslog::input::file { 'gerrit-apache2-error':
        path => "${gerrit_site}/logs/gerrit*error*.log",
    }
    rsyslog::input::file { 'gerrit-apache2-access':
        path => "${gerrit_site}/logs/gerrit*access*.log",
    }

    # have a different banner on primary host vs replicas (T392212)
    $motd_script = $is_replica ? {
        true    => 'replica',
        false   => 'primary',
        default => 'replica',
    }

    motd::script { "${motd_script} warning":
        ensure   => 'present',
        priority => 1,
        content  => template("profile/gerrit/${motd_script}.motd.erb"),
    }

}
