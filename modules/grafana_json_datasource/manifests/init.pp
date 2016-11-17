# == Class: grafana_json_datasource
#
# Grafana is an open-source, feature-rich dashboard and graph editor
# for Graphite and InfluxDB. See <http://grafana.org/> for details.
#
# This Grafana JSON datasource is a collection of simple scripts forming
# a web api endpoint conforming to the spec laid out in by:
# https://github.com/grafana/simple-json-datasource
#
class grafana_json_datasource(
    $site_name,
    $docroot
) {

    apache::site { $site_name:
        content => template('grafana_json_datasource/apache/grafana-json-datasource.wikimedia.org.erb');
    }

    file { '/srv/grafana_json_datasource':
        ensure => 'directory',
        owner  => 'www-data',
        group  => 'www-data',
    }

    $files = [
        'index.php',
        'annotations.php',
        'query.php',
        'search.php',
    ]

    file { "/srv/grafana_json_datasource/${files}":
        ensure => present,
        owner  => 'root',
        group  => 'root',
        source => "puppet:///modules/grafana_json_datasource/${files}",
    }
}
