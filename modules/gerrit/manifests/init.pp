# Manifest to setup a Gerrit instance
class gerrit(
    $host,
    $slave = false,
    $config,
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
