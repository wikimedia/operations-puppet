class mediawiki::web::config ($use_local_resources = true) {
    tag 'mediawiki', 'mw-apache-config'
    file { '/etc/apache2/wikimedia':
        ensure  => directory,
        recurse => true,
        source  => 'puppet:///modules/mediawiki/apache/config',
    }
    exec { 'sync_apache_config':
        command => '/usr/bin/rsync -av 10.0.5.8::httpdconf/ /usr/local/apache/conf',
        creates => '/usr/local/apache/conf',
        require => File['/usr/local/apache'],
        notify  => Service['apache'],
    }
}
