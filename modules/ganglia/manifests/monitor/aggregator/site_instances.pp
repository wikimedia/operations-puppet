# Instantiate aggregators for all clusters for this site ($title)
define ganglia::monitor::aggregator::site_instances() {
    $cluster_list = suffix(keys($ganglia::configuration::clusters), "_${title}")
    instance { $cluster_list:
        monitored_site => $title,
    }
}
