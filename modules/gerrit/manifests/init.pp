# Manifest to setup a Gerrit instance
class gerrit(
    $config,
    $host,
    $slave_hosts = [],
    $slave = false,
) {

    class { '::gerrit::jetty':
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
