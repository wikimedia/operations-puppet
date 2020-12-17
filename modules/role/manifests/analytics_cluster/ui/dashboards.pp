# Class: role::analytics_cluster::ui::dashboards
#
# Currently hosts memcached and Superset.
# Eventually will host Turnilo as well.
#
class role::analytics_cluster::ui::dashboards {
    system::role { 'analytics_cluster::ui::dashboards':
        description => 'Analytics dashboards: Turnilo and Superset web interfaces',
    }

    include ::profile::base::firewall
    include ::profile::standard
    include ::profile::superset
    include ::profile::tlsproxy::envoy
    include ::profile::kerberos::client
    include ::profile::kerberos::keytabs
    include ::profile::memcached::instance
}
