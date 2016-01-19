class mediawiki::web::sites {
    tag 'mediawiki', 'mw-apache-config'

    if $::realm == 'labs' {
        $domain_suffix = 'beta.wmflabs.org'
    } else {
        $domain_suffix = 'org'
    }

    apache::site { 'nonexistent':
        source   => 'puppet:///modules/mediawiki/apache/sites/nonexistent.conf',
        priority => 0,
    }

    apache::site { 'wwwportals':
        content  => template('mediawiki/apache/sites/wwwportals.conf.erb'),
        priority => 1,
    }
}
