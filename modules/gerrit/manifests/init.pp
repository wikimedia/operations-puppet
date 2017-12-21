# Manifest to setup a Gerrit instance
class gerrit(
    $config,
    $host,
    $ipv4,
    $ipv6,
    $slave_hosts = [],
    $slave = false,
    $log_host = undef,
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
        require     => Class['gerrit::jetty'],
        host        => $host,
        ipv4        => $ipv4,
        ipv6        => $ipv6,
        slave_hosts => $slave_hosts,
        slave       => $slave,
    }

    if !$slave {
        class { '::gerrit::crons':
            require => Class['gerrit::jetty'],
        }
    }
}
