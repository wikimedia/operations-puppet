# Manifest to setup a Gerrit instance

class gerrit($host = undef, $master_node = $::fqdn) {

    if $host == undef {
        fail('$gerrit::host must be set!')
    }

    # Are we a slave or a master?
    $slave = $master_node ? {
        $::fqdn => false,
        default => true,
    }

    class { 'gerrit::jetty':
        slave => $slave,
    }

    if !$slave {
        class { 'gerrit::proxy':
            require => Class['gerrit::jetty'],
        }
    }

    class { 'gerrit::crons':
        require => Class['gerrit::jetty'],
    }
}
