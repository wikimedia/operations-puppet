# Class: role::analytics_cluster::ui::dashboards
#
# Currently hosts memcached used by Superset.
# Eventually will host Turnilo and Superset as well.
#
class role::analytics_cluster::ui::dashboards {
    system::role { 'analytics_cluster::ui::dashboards':
        description => 'Analytics dashboards: Turnilo and Superset web interfaces',
    }

    include ::profile::base::firewall
    include ::profile::standard
    include profile::memcached::instance
}
