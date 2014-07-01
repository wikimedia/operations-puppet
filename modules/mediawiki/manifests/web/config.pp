class mediawiki::web::config () {
    tag 'mediawiki', 'mw-apache-config'
    file { '/etc/apache2/wikimedia':
        ensure  => directory,
        recurse => true,
        source  => 'puppet:///modules/mediawiki/apache/config',
        notify  => Service['apache'],
        before  => File['/etc/apache2/apache2.conf'],
    }
}
