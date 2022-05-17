# Class: role::analytics_cluster::ui::superset::staging
#
#
class role::analytics_cluster::ui::superset::staging {
    system::role { 'analytics_cluster::ui::superset::staging':
        description => 'Superset web GUI for analytics dashboards (staging environment)'
    }

    include ::profile::superset
    include ::profile::tlsproxy::envoy
    include ::profile::base::firewall
    include ::profile::base::production
    include ::profile::kerberos::client
    include ::profile::kerberos::keytabs
    include ::profile::memcached::instance
}
