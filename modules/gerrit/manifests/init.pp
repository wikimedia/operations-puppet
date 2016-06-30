# Manifest to setup a Gerrit instance

class gerrit(
    $host,
    $replication = ''
    ) {

    class { 'gerrit::jetty':
        replication => $replication,
    }

    class { 'gerrit::proxy':
        require => Class['gerrit::jetty'],
    }

    class { 'gerrit::crons':
        require => Class['gerrit::jetty'],
    }
}
