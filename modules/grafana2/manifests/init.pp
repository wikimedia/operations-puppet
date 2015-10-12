# == Class: grafana2
#
# Grafana is an open-source, feature-rich dashboard and graph editor
# for Graphite and InfluxDB. See <http://grafana.org/> for details.
#
# === Parameters
#
# [*config*]
#   A hash of Grafana configuration options.
#   For a list of available configuration options and their purpose,
#   see <http://docs.grafana.org/installation/configuration/>.
#
# === Examples
#
#  class { '::grafana2':
#    config => {
#      server => {
#          http_addr => '127.0.0.1',
#          domain    => 'grafana.wikimedia.org',
#      },
#    },
#  }
#
class grafana2( $config ) {
    require_package('grafana')

    file { '/etc/grafana/grafana.ini':
        content => php_ini($config),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    base::service_unit { 'grafana-server':
        systemd   => true,
        subscribe => File['/etc/grafana/grafana.ini'],
    }
}
