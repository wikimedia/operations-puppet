# == Class: role::grafana
#
# Grafana is an open-source, feature-rich metrics dashboard and graph
# editor for Graphite & InfluxDB. It powers <https://grafana.wikimedia.org>.
#
class role::grafana {

    case $::realm {
        'labs': {
            require role::labs::lvm::srv
            $graphiteUrl = 'https://graphite.wmflabs.org'
        }
        default: {
            monitor_service { 'grafana':
                description   => 'grafana.wikimedia.org',
                check_command => 'check_http_url!grafana.wikimedia.org!/',
            }
            $graphiteUrl = 'https://graphite.wikimedia.org'
        }
    }

    class { '::grafana':
        config => { graphiteUrl => $graphiteUrl, },
    }

    class { 'grafana::web::nginx': }
}
