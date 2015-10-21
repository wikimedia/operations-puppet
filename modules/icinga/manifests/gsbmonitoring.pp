class icinga::gsbmonitoring {
    @monitoring::host { 'google':
        host_fqdn => 'google.com'
    }

    @monitoring::service { 'GSB_mediawiki':
        description   => 'check google safe browsing for mediawiki.org',
        check_command => 'check_https_url_for_string!www.google.com!/safebrowsing/diagnostic?output=jsonp&site=mediawiki.org/!\'"type": 4\'',
        host          => 'google',
    }
    @monitoring::service { 'GSB_wikibooks':
        description   => 'check google safe browsing for wikibooks.org',
        check_command => 'check_https_url_for_string!www.google.com!/safebrowsing/diagnostic?output=jsonp&site=wikibooks.org/!\'"type": 4\'',
        host          => 'google',
    }
    @monitoring::service { 'GSB_wikimedia':
        description   => 'check google safe browsing for wikimedia.org',
        check_command => 'check_https_url_for_string!www.google.com!/safebrowsing/diagnostic?output=jsonp&site=wikimedia.org/!\'"type": 4\'',
        host          => 'google',
    }
    @monitoring::service { 'GSB_wikinews':
        description   => 'check google safe browsing for wikinews.org',
        check_command => 'check_https_url_for_string!www.google.com!/safebrowsing/diagnostic?output=jsonp&site=wikinews.org/!\'"type": 4\'',
        host          => 'google',
    }
    @monitoring::service { 'GSB_wikipedia':
        description   => 'check google safe browsing for wikipedia.org',
        check_command => 'check_https_url_for_string!www.google.com!/safebrowsing/diagnostic?output=jsonp&site=wikipedia.org/!\'"type": 4\'',
        host          => 'google',
    }
    @monitoring::service { 'GSB_wikiquote':
        description   => 'check google safe browsing for wikiquote.org',
        check_command => 'check_https_url_for_string!www.google.com!/safebrowsing/diagnostic?output=jsonp&site=wikiquote.org/!\'"type": 4\'',
        host          => 'google',
    }
    @monitoring::service { 'GSB_wikisource':
        description   => 'check google safe browsing for wikisource.org',
        check_command => 'check_https_url_for_string!www.google.com!/safebrowsing/diagnostic?output=jsonp&site=wikisource.org/!\'"type": 4\'',
        host          => 'google',
    }
    @monitoring::service { 'GSB_wikiversity':
        description   => 'check google safe browsing for wikiversity.org',
        check_command => 'check_https_url_for_string!www.google.com!/safebrowsing/diagnostic?output=jsonp&site=wikiversity.org/!\'"type": 4\'',
        host          => 'google',
    }
    @monitoring::service { 'GSB_wiktionary':
        description   => 'check google safe browsing for wiktionary.org',
        check_command => 'check_https_url_for_string!www.google.com!/safebrowsing/diagnostic?output=jsonp&site=wiktionary.org/!\'"type": 4\'',
        host          => 'google',
    }
}
