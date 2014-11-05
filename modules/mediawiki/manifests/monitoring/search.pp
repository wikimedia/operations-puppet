# monitor the Apple dictionary bridge (RT #6128)
class mediawiki::monitoring::search {

    # add virtual host for icinga to add the service to
    @monitor_host { 'search.wikimedia.org':
        ip_address => '208.80.154.224',
    }

    # http://search.wikimedia.org/?lang=en&site=wikipedia&search=Wikimedia_Foundation&limit=1
    monitor_service { 'mediawiki-dict-bridge':
        description   => 'Mediawiki Apple Dictionary Bridge',
        check_command => 'check_https_dictbridge',
    }

}

