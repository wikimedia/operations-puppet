# == Class: role::grafana
#
# Grafana is an open-source, feature-rich metrics dashboard and graph
# editor for Graphite & InfluxDB. It powers <https://grafana.wikimedia.org>.
#
class role::grafana {

    include base::firewall

    $domain_suffix = $::realm ? {
        production => 'wikimedia.org',
        labs       => 'wmflabs.org',
    }

    class { '::grafana':
        config => {
            datasources => {
                graphite      => {
                    'default'     => true,
                    type          => 'graphite',
                    url           => "//graphite.${domain_suffix}",
                    render_method => 'GET',
                },
                elasticsearch => {
                    type      => 'elasticsearch',
                    url       => "//grafana.${domain_suffix}",
                    index     => 'grafana-dashboards',
                    grafanaDB => true,
                },
            },
            default_route => '/dashboard/db/home',
        },
    }

    class { '::grafana::web::apache':
        server_name      => "grafana.${domain_suffix}",
        elastic_backends => [
            'http://logstash1001.eqiad.wmnet:9200',
            'http://logstash1002.eqiad.wmnet:9200',
            'http://logstash1003.eqiad.wmnet:9200',
        ],
    }

    monitoring::service { 'grafana':
        description   => "grafana.${domain_suffix}",
        check_command => "check_http_url!grafana.${domain_suffix}!/",
    }

    ferm::service { 'grafana_http':
        proto => 'tcp',
        port  => '80',
    }

}
