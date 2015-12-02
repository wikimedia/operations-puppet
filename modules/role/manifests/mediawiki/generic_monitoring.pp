class role::mediawiki::generic_monitoring {
    # Will use the local MediaWiki install so that we can use
    # maintenance scripts recycling DB connections and taking a few secs,
    # not mins

    # monitor the Apple dictionary bridge (T83147)
    # https://search.wikimedia.org/?lang=en&site=wikipedia&search=Wikimedia_Foundation&limit=1
    monitoring::service { 'mediawiki-dict-bridge':
        description   => 'Mediawiki Apple Dictionary Bridge',
        check_command => 'check_https_dictbridge',
    }
}

