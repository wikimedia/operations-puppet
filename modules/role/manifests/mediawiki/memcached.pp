# Role for the MediaWiki memcached+redis-sessions role for production.
class role::mediawiki::memcached inherits role::memcached {
    include ::profile::redis::multidc

    system::role { 'mediawiki::memcached':
        description => 'memcached+redis sessions',
    }
}
