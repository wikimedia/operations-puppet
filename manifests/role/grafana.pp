# == Class: role::grafana
#
# Grafana is an open-source, feature-rich metrics dashboard and graph
# editor for Graphite & InfluxDB. It powers <https://grafana.wikimedia.org>.
#
class role::grafana {

    if ($::realm == 'labs') {
        # Mount extra disk on /srv so we have somewhere to deploy
        require role::labs::lvm::srv
    }

    case $::realm {
        'labs': { $graphiteUrl = 'graphite.wmflabs.org' }
        default: { $graphiteUrl = 'graphite.wikimedia.org' }
    }

    class { '::grafana':
        config => { graphiteUrl => $graphiteUrl, },
    }

    class { 'grafana::web::nginx': }

    if $::realm == 'production' {
        monitor_service { 'grafana':
            description   => 'grafana.wikimedia.org',
            check_command => 'check_http_url!grafana.wikimedia.org!/',
        }
    }
}
