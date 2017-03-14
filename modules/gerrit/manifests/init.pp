# Manifest to setup a Gerrit instance
class gerrit(
    $host = undef,
    $master_host = $::fqdn,
) {

    if $host == undef {
        fail('$gerrit::host must be set!')
    }

    $slave = $master_host ? {
        $::fqdn => false,
        default => true
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
