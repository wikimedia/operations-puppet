# == Class: grafana
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
# [*ldap*]
#   A hash meant of ldap.toml configuration options
#   See http://docs.grafana.org/installation/ldap/
#
# === Examples
#
#  class { '::grafana':
#    config => {
#      server => {
#          http_addr => '127.0.0.1',
#          domain    => 'grafana.wikimedia.org',
#      },
#    },
#  }
#
class grafana(
    $config,
    $ldap = undef,
) {

    $defaults = {
        'dashboards.json' => {
            enabled => true,
            path    => '/var/lib/grafana/dashboards',
        },
    }

    package { 'grafana':
        ensure => present,
    }

    file { '/etc/grafana/grafana.ini':
        content => ini($defaults, $config),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package['grafana'],
    }

    file { '/var/lib/grafana/dashboards':
        ensure  => directory,
        owner   => 'grafana',
        group   => 'grafana',
        mode    => '0755',
        recurse => true,
        purge   => true,
        force   => true,
        require => Package['grafana'],
    }

    service { 'grafana-server':
        ensure    => running,
        enable    => true,
        provider  => 'systemd',
        subscribe => [
            File['/etc/grafana/grafana.ini'],
            Package['grafana'],
        ],
    }

    if $ldap {
        file { '/etc/grafana/ldap.toml':
            owner   => 'root',
            group   => 'root',
            mode    => '0400',
            content => template('grafana/ldap.toml.erb'),
        }
    }

}
