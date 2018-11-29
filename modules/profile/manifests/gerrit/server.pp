# modules/profile/manifests/gerrit/server.pp
#
# filtertags: labs-project-git
class profile::gerrit::server(
    $ipv4 = hiera('gerrit::service::ipv4'),
    $ipv6 = hiera('gerrit::service::ipv6', undef),
    $host = hiera('gerrit::server::host'),
    $avatars_host = hiera('gerrit::server::avatars_host', undef),
    $slave_hosts = hiera('gerrit::server::slave_hosts'),
    $master_host = hiera('gerrit::server::master_host'),
    $bacula = hiera('gerrit::server::bacula'),
    $gerrit_servers = join(hiera('gerrit::servers'), ' '),
    $config = hiera('gerrit::server::config'),
    $log_host = hiera('logstash_host'),
    $cache_text_nodes = hiera('cache::text::nodes', []),
    $use_certcentral = hiera('gerrit::server::use_certcentral', false),
) {

    interface::alias { 'gerrit server':
        ipv4 => $ipv4,
        ipv6 => $ipv6,
    }

    # Detect if we're a master or a slave. If we're been given a master host
    # and it's not us, we're not a master. If we are that host, we are
    # (obviously). If we're not given any master, assume we're working by
    # ourselves (safest).
    $slave = $master_host ? {
        $::fqdn => false,
        undef   => false,
        default => true,
    }

    if !$slave {
        monitoring::service { 'gerrit_ssh':
            description   => 'SSH access',
            check_command => "check_ssh_port_ip!29418!${ipv4}",
            contact_group => 'admins,gerrit',
        }
    }

    # ssh from users to gerrit
    ferm::service { 'gerrit_ssh_users':
        proto => 'tcp',
        port  => '29418',
    }

    # ssh between gerrit servers for cluster support
    ferm::service { 'gerrit_ssh_cluster':
        port   => '22',
        proto  => 'tcp',
        srange => "(@resolve((${gerrit_servers})) @resolve((${gerrit_servers}), AAAA))",
    }

    ferm::service { 'gerrit_http':
        proto => 'tcp',
        port  => 'http',
    }

    ferm::service { 'gerrit_https':
        proto => 'tcp',
        port  => 'https',
    }

    if $bacula != undef and !$slave {
        backup::set { $bacula:
            jobdefaults => "Hourly-${profile::backup::host::day}-${profile::backup::host::pool}"
        }
    }

    if $use_certcentral {
        class { '::sslcert::dhparam': }
        certcentral::cert { 'gerrit':
            puppet_svc => 'apache2',
        }
    } else {
        if $slave {
            $tls_host = $slave_hosts[0]
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
        host             => $host,
        ipv4             => $ipv4,
        ipv6             => $ipv6,
        slave            => $slave,
        slave_hosts      => $slave_hosts,
        config           => $config,
        log_host         => $log_host,
        avatars_host     => $avatars_host,
        cache_text_nodes => $cache_text_nodes,
        use_certcentral  => $use_certcentral,
    }

    class { '::gerrit::replication_key':
        require => Class['gerrit'],
    }

    # Ship gerrit logs to ELK using startmsg_regex pattern to join multi-line events based on datestamp
    # example: [2018-11-28 21:53:07,446]
    rsyslog::input::file { 'gerrit-multiline':
        path           => '/var/log/gerrit/*_log',
        startmsg_regex => '^\\\\[[0-9,-\\\\ \\\\:]+\\\\]',
    }

}
