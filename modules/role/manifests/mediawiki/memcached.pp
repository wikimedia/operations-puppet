# Role for the MediaWiki memcached+redis-sessions role for production.
class role::mediawiki::memcached{

    system::role { 'mediawiki::memcached':
        description => 'memcached',
    }

    include ::profile::base::production
    include ::profile::firewall
    include profile::memcached::instance
    include profile::memcached::memkeys
    include profile::memcached::performance
}
