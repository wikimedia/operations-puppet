# Manifest to setup a Gerrit instance

class gerrit($host = undef) {

    if $host == undef {
        fail('$gerrit::host must be set!')
    }

    class { 'gerrit::jetty': }

    class { 'gerrit::proxy':
        require => Class['gerrit::jetty'],
    }

    class { 'gerrit::crons':
        require => Class['gerrit::jetty'],
    }
}
