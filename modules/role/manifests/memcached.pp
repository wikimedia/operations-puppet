# vim: noet
#
# filtertags: labs-project-deployment-prep
class role::memcached {
    system::role { 'role::memcached': }

    include ::standard
    include base::mysterious_sysctl
    include base::firewall
    include profile::memcached::instance
    include profile::memcached::memkeys
    include profile::redis::multidc_instance
}
