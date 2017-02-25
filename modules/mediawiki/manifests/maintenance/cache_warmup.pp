class mediawiki::maintenance::cache_warmup( $ensure = present ) {
    # Include this on a maintenance host to run APC/Memcached warmup
    # after resetting caches (e.g. during a dc switchover)
    # https://phabricator.wikimedia.org/T156922
    # Hopefully this will be obsolete soon enough when we run active-active.

    require_package('nodejs')

    file { '/var/lib/mediawiki-cache-warmup':
        ensure => ensure_directory($ensure),
        owner  => $::mediawiki::users::web,
        group  => 'wikidev',
        mode   => '0775',
    }

    file { '/var/lib/mediawiki-cache-warmup/util.js':
        ensure => $ensure,
        owner  => $::mediawiki::users::web,
        group  => 'wikidev',
        mode   => '0664',
        source => 'puppet:///modules/mediawiki/maintenance/mediawiki-cache-warmup/util.js',
    }
    file { '/var/lib/mediawiki-cache-warmup/warmup.js':
        ensure => $ensure,
        owner  => $::mediawiki::users::web,
        group  => 'wikidev',
        mode   => '0664',
        source => 'puppet:///modules/mediawiki/maintenance/mediawiki-cache-warmup/warmup.js',
    }
    file { '/var/lib/mediawiki-cache-warmup/urls-cluster.txt':
        ensure => $ensure,
        owner  => $::mediawiki::users::web,
        group  => 'wikidev',
        mode   => '0664',
        source => 'puppet:///modules/mediawiki/maintenance/mediawiki-cache-warmup/urls-cluster.txt',
    }
    file { '/var/lib/mediawiki-cache-warmup/url-server.txt':
        ensure => $ensure,
        owner  => $::mediawiki::users::web,
        group  => 'wikidev',
        mode   => '0664',
        source => 'puppet:///modules/mediawiki/maintenance/mediawiki-cache-warmup/url-server.txt',
    }
    file { '/var/lib/mediawiki-cache-warmup/README.md':
        ensure => $ensure,
        owner  => $::mediawiki::users::web,
        group  => 'wikidev',
        mode   => '0664',
        source => 'puppet:///modules/mediawiki/maintenance/mediawiki-cache-warmup/util.js',
    }
}
