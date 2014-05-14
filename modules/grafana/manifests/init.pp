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
    $defaults = {
        default_route           => '/dashboard/file/default.json',
        timezoneOffset          => '0000',  # UTC
        grafana_index           => 'grafana-dash',
        unsaved_changes_warning => true,
        panel_names             => [ 'text', 'graphite' ],
    }

    deployment::target { 'grafana': }

    file { '/etc/grafana':
        ensure => directory,
    }

    file { '/etc/grafana/config.js':
        content => template('grafana/config.js.erb'),
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '0644',
    }
}
