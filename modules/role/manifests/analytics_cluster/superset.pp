# Class: role::analytics_cluster::superset
#
#
class role::analytics_cluster::superset {
    system::role { 'analytics_cluster::superset':
        description => 'Superset web GUI for analytics dashboards'
    }

    include ::profile::superset
    include ::profile::base::firewall
    include ::profile::standard
}
