# Class: role::analytics_cluster::superset::staging
#
#
class role::analytics_cluster::superset::staging {
    system::role { 'analytics_cluster::superset::staging':
        description => 'Superset web GUI for analytics dashboards (staging environment)'
    }

    include ::profile::superset
    include ::profile::base::firewall
    include ::profile::standard
}
