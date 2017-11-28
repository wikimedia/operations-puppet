class mediawiki::maintenance::cache_warmup( $ensure = present ) {
    # Include this on a maintenance host to run APC/Memcached warmup
    # after resetting caches (e.g. during a dc switchover)
    # https://phabricator.wikimedia.org/T156922
    # Hopefully this will be obsolete soon enough when we run active-active.

    require_package('nodejs')

    # Ensure all files we have in puppet are present in the directory, but allow
    # users to write files in the directory without purging them.
    file { '/var/lib/mediawiki-cache-warmup':
        ensure  => ensure_directory($ensure),
        owner   => $::mediawiki::users::web,
        recurse => remote,
        group   => 'wikidev',
        mode    => '0775',
        source  => 'puppet:///modules/mediawiki/maintenance/mediawiki-cache-warmup/',
    }

}
