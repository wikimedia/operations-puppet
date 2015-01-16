class icinga::gsbmonitoring {
    @monitoring::host { 'google':
        host_fqdn => 'google.com'
    }

    @monitoring::service { 'GSB_mediawiki':
        description   => 'check google safe browsing for mediawiki.org',
        check_command => 'check_http_url_for_string!www.google.com!/safebrowsing/diagnostic?site=mediawiki.org/!\'This site is not currently listed as suspicious\'',
        host          => 'google',
    }
    @monitoring::service { 'GSB_wikibooks':
        description   => 'check google safe browsing for wikibooks.org',
        check_command => 'check_http_url_for_string!www.google.com!/safebrowsing/diagnostic?site=wikibooks.org/!\'This site is not currently listed as suspicious\'',
        host          => 'google',
    }
    @monitoring::service { 'GSB_wikimedia':
        description   => 'check google safe browsing for wikimedia.org',
        check_command => 'check_http_url_for_string!www.google.com!/safebrowsing/diagnostic?site=wikimedia.org/!\'This site is not currently listed as suspicious\'',
        host          => 'google',
    }
    @monitoring::service { 'GSB_wikinews':
        description   => 'check google safe browsing for wikinews.org',
        check_command => 'check_http_url_for_string!www.google.com!/safebrowsing/diagnostic?site=wikinews.org/!\'This site is not currently listed as suspicious\'',
        host          => 'google',
    }
    @monitoring::service { 'GSB_wikipedia':
        description   => 'check google safe browsing for wikipedia.org',
        check_command => 'check_http_url_for_string!www.google.com!/safebrowsing/diagnostic?site=wikipedia.org/!\'This site is not currently listed as suspicious\'',
        host          => 'google',
    }
    @monitoring::service { 'GSB_wikiquotes':
        description   => 'check google safe browsing for wikiquotes.org',
        check_command => 'check_http_url_for_string!www.google.com!/safebrowsing/diagnostic?site=wikiquotes.org/!\'This site is not currently listed as suspicious\'',
        host          => 'google',
    }
    @monitoring::service { 'GSB_wikisource':
        description   => 'check google safe browsing for wikisource.org',
        check_command => 'check_http_url_for_string!www.google.com!/safebrowsing/diagnostic?site=wikisource.org/!\'This site is not currently listed as suspicious\'',
        host          => 'google',
    }
    @monitoring::service { 'GSB_wikiversity':
        description   => 'check google safe browsing for wikiversity.org',
        check_command => 'check_http_url_for_string!www.google.com!/safebrowsing/diagnostic?site=wikiversity.org/!\'This site is not currently listed as suspicious\'',
        host          => 'google',
    }
    @monitoring::service { 'GSB_wiktionary':
        description   => 'check google safe browsing for wiktionary.org',
        check_command => 'check_http_url_for_string!www.google.com!/safebrowsing/diagnostic?site=wiktionary.org/!\'This site is not currently listed as suspicious\'',
        host          => 'google',
    }
}
