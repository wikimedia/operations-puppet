# Manifest to setup a Gerrit instance
class gerrit(
    $host,
    $master_host = $::fqdn,
) {

    $slave = $master_host ? {
        $::fqdn => false,
        default => true,
    }

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
