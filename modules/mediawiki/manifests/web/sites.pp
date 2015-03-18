class mediawiki::web::sites {
    tag 'mediawiki', 'mw-apache-config'

    # Now the sites, in strict sequence
    apache::site { 'nonexistent':
        source   => 'puppet:///modules/mediawiki/apache/sites/nonexistent.conf',
        priority => 0,
    }
}
