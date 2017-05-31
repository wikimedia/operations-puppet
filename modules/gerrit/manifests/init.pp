# Manifest to setup a Gerrit instance
class gerrit(
    $host,
    $slave_hosts = [],
    $slave = false,
) {

    class { '::gerrit::jetty':
        slave => $slave,
    }

    class { '::gerrit::proxy':
        require     => Class['gerrit::jetty'],
        slave_hosts => $slave_hosts,
    }

    if !$slave {
        class { '::gerrit::crons':
            require => Class['gerrit::jetty'],
        }
    }
}
