# Class: role::analytics_cluster::ui::superset
#
# Host for production Superset.
#
class role::analytics_cluster::ui::superset {
    system::role { 'analytics_cluster::ui::superset':
        description => 'Analytics Superset web interface',
    }

    include ::profile::base::firewall
    include ::profile::standard
    include ::profile::superset
    include ::profile::tlsproxy::envoy
    include ::profile::kerberos::client
    include ::profile::kerberos::keytabs
    include ::profile::memcached::instance
}
