class mediawiki::web::sites {
    tag 'mediawiki', 'mw-apache-config'

    apache::site { 'nonexistent':
        source   => 'puppet:///modules/mediawiki/apache/sites/nonexistent.conf',
        priority => 0,
    }
}
