# Manifest to setup a Gerrit instance
class gerrit(
    String $config,
    Stdlib::Fqdn $host,
    Stdlib::Ipv4 $ipv4,
    Array[Stdlib::Fqdn] $slave_hosts = [],
    Boolean $slave = false,
    Hash $cache_text_nodes = {},
    Boolean $use_acmechief = false,
    Optional[Hash] $ldap_config = undef,
    Optional[Stdlib::Ipv6] $ipv6,
    Optional[Stdlib::Fqdn] $avatars_host = undef,
) {

    class { '::gerrit::jetty':
        host        => $host,
        ipv4        => $ipv4,
        ipv6        => $ipv6,
        slave       => $slave,
        slave_hosts => $slave_hosts,
        config      => $config,
        ldap_config => $ldap_config,
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
        use_acmechief    => $use_acmechief,
    }

    if !$slave {
        class { '::gerrit::crons':
            require => Class['gerrit::jetty'],
        }
    }
}
