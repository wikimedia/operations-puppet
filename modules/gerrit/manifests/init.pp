# Manifest to setup a Gerrit instance
class gerrit(
    $ipv4,
    $ipv6,
    $config,
    $host,
    $slave = false,
) {

    class { '::gerrit::jetty':
        ipv4   => $ipv4,
        ipv6   => $ipv6,
        slave  => $slave,
        config => $config,
    }

    if !$slave {
        class { '::gerrit::proxy':
            require => Class['gerrit::jetty'],
        }

        class { '::gerrit::crons':
            require => Class['gerrit::jetty'],
        }
    }
}
