class mediawiki::web::sites {
    tag 'mediawiki', 'mw-apache-config'

    file { '/etc/apache2/includes':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
    }

    file { '/etc/apache2/mw-includes/engine_rewrite.conf':
        ensure => present,
        owner  => root,
        group  => root,
        source => 'puppet:///modules/mediawiki/apache/sites/include_engine_rewrite.conf',
        notify => Service['apache2'],
    }

    file { '/etc/apache2/mw-includes/hhvm_proxy.conf':
        ensure => present,
        owner  => root,
        group  => root,
        source => 'puppet:///modules/mediawiki/apache/sites/include_hhvm_proxy.conf',
        notify => Service['apache2'],
    }

    # Now the sites, in strict sequence
    apache::site { 'nonexistent':
        source   => 'puppet:///modules/mediawiki/apache/sites/nonexistent.conf',
        priority => 0,
    }

    apache::site { 'wwwportals':
        source   => 'puppet:///modules/mediawiki/apache/sites/wwwportals.conf',
        priority => 1,
    }

    apache::site { 'redirects':
        # this must be generated with the redirects.dat file still in apache-config,
        # then committed to puppet. This will change soon.
        source   => 'puppet:///modules/mediawiki/apache/sites/redirects.conf',
        priority => 2,
    }

    apache::site { 'main':
        source   => 'puppet:///modules/mediawiki/apache/sites/main.conf',
        priority => 3,
    }

    apache::site { 'remnant':
        source   => 'puppet:///modules/mediawiki/apache/sites/remnant.conf',
        priority => 4,
    }

    apache::site { 'search.wikimedia':
        source   => 'puppet:///modules/mediawiki/apache/sites/search.wikimedia.conf',
        priority => 5,
    }

    apache::site { 'secure.wikimedia':
        source   => 'puppet:///modules/mediawiki/apache/sites/secure.wikimedia.conf',
        priority => 6,
    }

    apache::site { 'wikimania':
        source   => 'puppet:///modules/mediawiki/apache/sites/wikimania.conf',
        priority => 7,
    }

    apache::site { 'wikimedia':
        source   => 'puppet:///modules/mediawiki/apache/sites/wikimedia.conf',
        priority => 8,
    }

    apache::site { 'foundation':
        source   => 'puppet:///modules/mediawiki/apache/sites/foundation.conf',
        priority => 9,
    }
}
