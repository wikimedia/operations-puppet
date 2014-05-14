# == Class: role::grafana
#
# Grafana is an open-source, feature-rich metrics dashboard and graph
# editor for Graphite & InfluxDB. It powers <https://grafana.wikimedia.org>.
#
class role::grafana {
    $domain_suffix = $::realm ? {
        production => 'wikimedia.org',
        labs       => 'wmflabs.org',
    }

    class { '::grafana':
        config => {
            datasources => {
                graphite => {
                    type => 'graphite',
                    url  => "graphite.${domain_suffix}",
                },
            },
        },
    }

    class { '::grafana::web::apache':
        site_name => "grafana.${domain_suffix}",
    }

    monitor_service { 'grafana':
        description   => "grafana.${domain_suffix}",
        check_command => "check_http_url!grafana.${domain_suffix}!/",
    }
}
