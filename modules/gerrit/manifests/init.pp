# Manifest to setup a Gerrit instance
class gerrit(
    $host,
    $slave = false,
) {

    class { '::gerrit::jetty':
        slave => $slave,
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
