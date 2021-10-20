# vim: noet
#
class role::memcached {
    system::role { 'memcached': }

    include ::profile::base::production
    include ::profile::base::firewall
    include profile::memcached::instance
    include profile::memcached::memkeys
    include profile::memcached::performance

}
