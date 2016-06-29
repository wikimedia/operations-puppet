# Manifest to setup a Gerrit instance

class gerrit(
    $host        = '',
    $replication = '',
    $smtp_host   = ''
    ) {

    # Configure the base URL
    $url = "https://${host}/r"

    class { 'gerrit::proxy':
        host         => $host
    }

    class { 'gerrit::jetty':
        url         => $url,
        hostname    => $host,
        replication => $replication,
        smtp_host   => $smtp_host,
    }

    class { 'gerrit::crons':
        require => Class['gerrit::jetty'],
    }
}
