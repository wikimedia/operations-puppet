# wikistats - mediawiki statistics site
# not to be confused with stats.wm

class wikistats ( $wikistats_host, $wikistats_ssl_cert, $wikistats_ssl_key ) {

    systemuser { 'wikistatsuser':
        name   => 'wikistats',
        home   => '/usr/lib/wikistats',
        groups => [ 'wikistats' ],
    }

    class { 'wikistats::web':
        wikistats_host     => $wikistats_host,
        wikistats_ssl_cert => $wikistats_ssl_cert,
        wikistats_ssl_key  => $wikistats_ssl_key,
    }

    class { 'wikistats::updates': }

}

