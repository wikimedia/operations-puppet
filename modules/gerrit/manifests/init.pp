# Manifest to setup a Gerrit instance
class gerrit(
    $ipv4,
    $ipv6,
    $config,
    $host,
    $slave_hosts = [],
    $slave = false,
) {

    class { '::gerrit::jetty':
        ipv4   => $ipv4,
        ipv6   => $ipv6,
        slave  => $slave,
        config => $config,
    }

    class { '::gerrit::proxy':
        require     => Class['gerrit::jetty'],
        host        => $host,
        slave_hosts => $slave_hosts,
        slave       => $slave,
    }

    if !$slave {
        class { '::gerrit::crons':
            require => Class['gerrit::jetty'],
        }
    }
}
