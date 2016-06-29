# Manifest to setup a Gerrit instance

class gerrit(
    $replication = '',
    $smtp_host   = ''
    ) {

    class { 'gerrit::jetty':
        replication => $replication,
        smtp_host   => $smtp_host,
    }

    class { 'gerrit::proxy':
        require => Class['gerrit::jetty'],
    }

    class { 'gerrit::crons':
        require => Class['gerrit::jetty'],
    }
}
