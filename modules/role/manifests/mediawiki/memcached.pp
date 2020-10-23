# Role for the MediaWiki memcached+redis-sessions role for production.
class role::mediawiki::memcached inherits role::memcached {

    # Trying out buster on one shard (T252391)
    if os_version('debian == jessie') {
        include ::profile::redis::multidc
    }
    system::role { 'mediawiki::memcached':
        description => 'memcached+redis sessions',
    }
}
