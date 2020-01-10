# Role for the MediaWiki memcached gutter/failover cluster role for production.
class role::mediawiki::memcached::gutter {

    system::role { 'mediawiki::memcached::gutter':
        description => 'memcached gutter/failover cluster',
    }

    include ::profile::standard
    include ::profile::base::firewall
    include profile::memcached::instance
    include profile::memcached::memkeys
    include profile::memcached::performance

}
