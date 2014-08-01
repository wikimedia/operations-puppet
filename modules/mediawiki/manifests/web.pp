class mediawiki::web( $workers_limit = undef ) {
    tag 'mediawiki', 'mw-apache-config'

    include ::apache
    include ::mediawiki
    include ::mediawiki::monitoring::webserver
    include ::mediawiki::web::envvars
    include ::mediawiki::web::modules

    $apache_server_limit = 256

    if is_integer($workers_limit) {
        $max_req_workers = min($workers_limit, $apache_server_limit)
    } else {
        $mem_available   = to_bytes($::memorytotal) * 0.7
        $mem_per_worker  = to_bytes('85M')
        $max_req_workers = min(floor($mem_available /$mem_per_worker), $apache_server_limit)
    }

    file { '/etc/apache2/apache2.conf':
        source  => 'puppet:///modules/mediawiki/apache/apache2.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        before  => Service['apache2'],
        require => Package['apache2'],
    }

    apache::conf { 'prefork':
        content  => template('mediawiki/apache/prefork.conf.erb'),
    }
}
