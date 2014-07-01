class mediawiki::web::config ($use_local_resources = false) {
    tag 'mediawiki', 'mw-apache-config'
    if $use_local_resources {
        file { '/etc/apache2/wikimedia':
            ensure  => directory,
            recurse => true,
            source  => 'puppet:///modules/mediawiki/apache/config',
            notify  => Service['apache'],
            before  => File['/etc/apache2/apache2.conf'],
        }
    } else {
        exec { 'sync_apache_config':
            command => '/usr/bin/rsync -av 10.0.5.8::httpdconf/ /usr/local/apache/conf',
            creates => '/usr/local/apache/conf',
            require => File['/usr/local/apache'],
            notify  => Service['apache'],
        }
    }
}
