# Manifest to setup a Gerrit instance
class gerrit(
    String $config,
    Stdlib::Fqdn $host,
    Stdlib::Ipv4 $ipv4,
    Optional[Stdlib::Ipv6] $ipv6,
    Array[Stdlib::Fqdn] $slave_hosts = [],
    Boolean $slave = false,
    Optional[Stdlib::Fqdn] $log_host = undef,
    Optional[Stdlib::Fqdn] $avatars_host = undef,
    Hash $cache_text_nodes = {},
    Boolean $use_certcentral = false,
) {

    class { '::gerrit::jetty':
        host     => $host,
        ipv4     => $ipv4,
        ipv6     => $ipv6,
        slave    => $slave,
        config   => $config,
        log_host => $log_host,
    }

    class { '::gerrit::proxy':
        require          => Class['gerrit::jetty'],
        host             => $host,
        ipv4             => $ipv4,
        ipv6             => $ipv6,
        slave_hosts      => $slave_hosts,
        slave            => $slave,
        avatars_host     => $avatars_host,
        cache_text_nodes => $cache_text_nodes,
        use_certcentral  => $use_certcentral,
    }

    if !$slave {
        class { '::gerrit::crons':
            require => Class['gerrit::jetty'],
        }
    }
}
