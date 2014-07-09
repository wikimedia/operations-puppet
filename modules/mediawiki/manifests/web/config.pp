class mediawiki::web::config () {
    tag 'mediawiki', 'mw-apache-config'

    if is_integer($::mediawiki::web::workers_limit) {
        $max_req_workers = $::mediawiki::web::workers_limit
    } else {
        $mem_available   = to_bytes($::memorytotal) * 0.7
        $mem_per_worker  = to_bytes('85M')
        $max_req_workers = inline_template('<%= ( @mem_available / @mem_per_worker ).to_i %>')
    }

    file { '/etc/apache2/apache2.conf':
        content => template('mediawiki/apache/apache2.conf.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        before  => Service['apache'],
    }

    file { '/etc/apache2/envvars':
        source => 'puppet:///modules/mediawiki/apache/envvars.appserver',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        before => Service['apache'],
    }


    file { '/etc/apache2/wikimedia':
        ensure  => directory,
        recurse => true,
        source  => 'puppet:///modules/mediawiki/apache/config',
        before  => File['/etc/apache2/apache2.conf'],
    }
}
