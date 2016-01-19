class mediawiki::web::sites (
    $domain_suffix = 'org'
) {
    tag 'mediawiki', 'mw-apache-config'

    apache::site { 'nonexistent':
        source   => 'puppet:///modules/mediawiki/apache/sites/nonexistent.conf',
        priority => 0,
    }

    apache::site { 'wwwportals':
        content  => template('mediawiki/apache/sites/wwwportals.conf.erb'),
        priority => 1,
    }
}
