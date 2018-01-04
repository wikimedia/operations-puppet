class role::analytics_cluster::webserver {

    system::role { 'analytics_cluster::webserver':
        description => 'Webserver hosting the main Analytics websites'
    }

    include ::profile::statistics::web

    # Superset. T166689
    include ::profile::superset

    include ::profile::hue
    include ::profile::druid::pivot

    include ::profile::base::firewall
    include standard
}