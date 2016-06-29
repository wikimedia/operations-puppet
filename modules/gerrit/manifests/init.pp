# Manifest to setup a Gerrit instance

class gerrit(
    $host        = '',
    $replication = ''
    ) {

    class { 'gerrit::proxy':
        host => $host
    }

    class { 'gerrit::jetty':
        replication => $replication,
    }

    class { 'gerrit::crons':
        require => Class['gerrit::jetty'],
    }
}
