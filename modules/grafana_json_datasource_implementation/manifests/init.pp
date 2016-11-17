# == Class: grafana_json_datasource_implementation
#
# Grafana is an open-source, feature-rich dashboard and graph editor
# for Graphite and InfluxDB. See <http://grafana.org/> for details.
#
# The Grafana JSON datasource is a plugin that allows reading data form
# a simple JSON based API.
#
# This module pulls in an implementation API made up of a few simple scripts
# conforming to the spec laid out in by:
# https://github.com/grafana/simple-json-datasource
#
class grafana_json_datasource_implementation(
    $site_name,
    $docroot
) {

    apache::site { $site_name:
        content => template('grafana_json_datasource/apache/grafana-json-datasource.wikimedia.org.erb');
    }

    file { '/srv/grafana_json_datasource_implementation':
        ensure => 'directory',
        owner  => 'www-data',
        group  => 'www-data',
    }

    git::clone { 'operations/software/grafana/simple-json-datasource-implementation':
        ensure    => present,
        branch    => 'master',
        directory => '/srv/grafana_json_datasource_implementation',
    }
}
