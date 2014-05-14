# == Class: grafana
#
# Grafana is an open-source, feature-rich dashboard and graph editor
# for Graphite and InfluxDB. See <http://grafana.org/> for details.
#
# Grafana only has one optional external dependency and that is
# Elasticsearch. Elasticsearch is used to store, load and search for
# dashboards. But you can use Grafana without it.
#
# === Parameters
#
# [*config*]
#   A hash of Grafana configuration options.
#   For an annotated example of possible configuration values, see
#   <https://github.com/grafana/grafana/blob/master/src/config.sample.js>
#
# === Examples
#
#  class { 'grafana':
#    config => {
#      graphiteUrl   => 'https://graphite.wikimedia.org',
#      elasticsearch => 'https://elastic.wikimedia.org',
#    },
#  }
#
class grafana( $config ) {
    package { 'grafana':
        provider => 'trebuchet',
    }

    file { '/etc/grafana':
        ensure => directory,
    }

    file { '/etc/grafana/config.js':
        content => template('grafana/config.js.erb'),
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '0444',
    }
}
