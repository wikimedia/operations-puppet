# Manifest to setup a Gerrit instance

class gerrit(
    $host        = '',
    $replication = '',
    $smtp_host   = ''
    ) {

    class { 'gerrit::proxy':
        host => $host
    }

    class { 'gerrit::jetty':
        replication => $replication,
        smtp_host   => $smtp_host,
    }

    class { 'gerrit::crons':
        require => Class['gerrit::jetty'],
    }
}
