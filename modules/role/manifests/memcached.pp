# vim: noet
#
# filtertags: labs-project-deployment-prep
class role::memcached {
    system::role { 'memcached': }

    include ::profile::standard
    include ::profile::base::firewall
    include profile::memcached::instance
    include profile::memcached::memkeys
    include profile::memcached::performance

}
