# Manifest to setup a Gerrit instance

class gerrit($host = undef, $slave = false) {

    if $host == undef {
        fail('$gerrit::host must be set!')
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
