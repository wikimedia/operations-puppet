# Manifest to setup a Gerrit instance
class gerrit(
    $config,
    $host,
    $slave = false,
) {

    class { '::gerrit::jetty':
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
