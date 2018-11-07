# vim: noet
#
# filtertags: labs-project-deployment-prep
class role::memcached {
    system::role { 'memcached': }

    include ::standard
    include ::base::mysterious_sysctl
    include ::profile::base::firewall
    include profile::memcached::instance
    include profile::memcached::memkeys

    interface::rps {
        $facts['interface_primary']:
    }
}
