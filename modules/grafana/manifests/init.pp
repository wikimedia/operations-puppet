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

    if os_version('debian >= stretch') {
        apt::repository { 'thirdparty-grafana':
            uri        => 'http://apt.wikimedia.org/wikimedia',
            dist       => "${::lsbdistcodename}-wikimedia",
            components => 'thirdparty/grafana',
            notify     => Exec['apt_update_grafana'],
            before     => Package['grafana']
        }

        exec {'apt_update_grafana':
            command     => '/usr/bin/apt-get update',
            refreshonly => true,
        }
    }

    package { 'grafana':
        ensure => present,
    }

    file { '/etc/grafana/grafana.ini':
        content => ini($defaults, $config),
        owner   => 'root',
        group   => 'grafana',
        mode    => '0440',
        require => Package['grafana'],
        # Explicit ordering to force first-run configuration options to be applied
        before  => Service['grafana-server'],
    }

    # If we're on Grafana 5.x, we need to install this yaml file to tell grafana
    # to read the dashboards from the place that earlier versions would
    # by default.  On earlier versions we don't want to install this, as the
    # directory will not exist.  Being on stretch is a proxy for grafana>=5
    if os_version('debian >= stretch') {
        file { '/etc/grafana/provisioning/dashboards/provision-puppet-dashboards.yaml':
            source  => 'puppet:///modules/grafana/provision-puppet-dashboards.yaml',
            owner   => 'root',
            group   => 'grafana',
            mode    => '0440',
            require => Package['grafana'],
            before  => Service['grafana-server'],
        }
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
            group   => 'grafana',
            mode    => '0440',
            content => template('grafana/ldap.toml.erb'),
            require => Package['grafana'],
            notify  => Service['grafana-server'],
            before  => Service['grafana-server'],
        }
    }

}
