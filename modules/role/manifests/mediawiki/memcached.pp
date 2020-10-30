# Role for the MediaWiki memcached+redis-sessions role for production.
class role::mediawiki::memcached{

    system::role { 'mediawiki::memcached':
        description => 'memcached+redis sessions',
    }

    include ::profile::standard
    include ::profile::base::firewall
    include profile::memcached::instance
    include profile::memcached::memkeys
    include profile::memcached::performance

    # Trying out buster on one shard (T252391)
    if debian::codename::eq('jessie') {
        include profile::redis::multidc
    }
}
