# Class: role::analytics_test_cluster::superset
#
#
class role::analytics_test_cluster::superset {
    system::role { 'analytics_test_cluster::superset':
        description => 'Superset web GUI for analytics dashboards'
    }

    include ::profile::superset
    include ::profile::base::firewall
    include standard
}