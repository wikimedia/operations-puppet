# modules/profile/manifests/gerrit/server.pp
#
# filtertags: labs-project-git
class profile::gerrit::server(
    Stdlib::Ipv4 $ipv4 = hiera('gerrit::service::ipv4'),
    Stdlib::Fqdn $host = hiera('gerrit::server::host'),
    Array[Stdlib::Fqdn] $slave_hosts = hiera('gerrit::server::slave_hosts'),
    Stdlib::Fqdn $master_host = hiera('gerrit::server::master_host'),
    String $bacula = hiera('gerrit::server::bacula'),
    Array[Stdlib::Fqdn] $gerrit_servers = hiera('gerrit::servers'),
    String $config = hiera('gerrit::server::config'),
    Hash $cache_nodes = hiera('cache::nodes', {}),
    Boolean $use_acmechief = hiera('gerrit::server::use_acmechief', false),
    Optional[Stdlib::Ipv6] $ipv6 = hiera('gerrit::service::ipv6', undef),
    Optional[Stdlib::Fqdn] $avatars_host = hiera('gerrit::server::avatars_host', undef),
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

    if $bacula != undef and !$slave {
        backup::set { $bacula:
            jobdefaults => "Hourly-${profile::backup::host::day}-${profile::backup::host::pool}"
        }
    }

    if $use_acmechief {
        class { '::sslcert::dhparam': }
        acme_chief::cert { 'gerrit':
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
        avatars_host     => $avatars_host,
        cache_text_nodes => pick($cache_nodes['text'], {}),
        use_acmechief    => $use_acmechief,
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
