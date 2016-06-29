# Manifest to setup a Gerrit instance

class gerrit(
    $db_host     = '',
    $host        = '',
    $ssh_key     = '',
    $ssl_cert    = 'ssl-cert-snakeoil',
    $ssl_cert_key= 'ssl-cert-snakeoil',
    $replication = '',
    $smtp_host   = ''
    ) {

    # Configure the base URL
    $url = "https://${host}/r"

    class { 'gerrit::proxy':
        ssl_cert     => $ssl_cert,
        ssl_cert_key => $ssl_cert_key,
        host         => $host
    }

    class { 'gerrit::jetty':
        url         => $url,
        db_host     => $db_host,
        hostname    => $host,
        replication => $replication,
        smtp_host   => $smtp_host,
        ssh_key     => $ssh_key,
    }

    class { 'gerrit::crons':
        require => Class['gerrit::jetty'],
    }
}
