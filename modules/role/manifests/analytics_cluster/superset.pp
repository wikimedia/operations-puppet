# Class: role::analytics_cluster::superset
#
#
class role::analytics_cluster::superset {
    system::role { 'analytics_cluster::superset':
        description => 'Superset web GUI for analytics dashboards'
    }

    include ::profile::superset
    include ::profile::tlsproxy::envoy
    include ::profile::base::firewall
    include ::profile::standard
    include ::profile::kerberos::client
    include ::profile::kerberos::keytabs
}
