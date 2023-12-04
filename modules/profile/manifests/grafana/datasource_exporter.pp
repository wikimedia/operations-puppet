# SPDX-License-Identifier: Apache-2.0
# == Class: profile::grafana::datasource_exporter
#
# Grafana datasource usage exporter

class profile::grafana::datasource_exporter (
    Wmflib::Ensure  $ensure          = lookup('profile::grafana::datasource_exporter::grafana_url', {'default_value' => 'present'}),
    Stdlib::HTTPUrl $grafana_url     = lookup('profile::grafana::datasource_exporter::grafana_url', {'default_value' => 'http://localhost:3000'}),
    Stdlib::HTTPUrl $pushgateway_url = lookup('profile::grafana::datasource_exporter::pushgateway_url', {'default_value' => 'http://prometheus-pushgateway.discovery.wmnet:80'}),
    String          $timer_interval  = lookup('profile::grafana::datasource_exporter::timer_interval', { 'default_value' => 'hourly' }),
) {

    file { '/usr/local/bin/grafana-datasource-exporter.py':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/grafana/grafana-datasource-exporter.py';
    }

    $timer_environment = {  'GRAFANA_URL'     => $grafana_url,
                            'PUSHGATEWAY_URL' => $pushgateway_url }

    systemd::timer::job { 'prometheus-grafana-datasource-exporter':
        ensure        => $ensure,
        description   => 'Send grafana dashboard graphite datasource usage metrics to promethues-pushgaeway',
        user          => 'grafana',
        ignore_errors => true,
        environment   => $timer_environment,
        command       => '/usr/local/bin/grafana-datasource-exporter.py',
        interval      => [ { 'start' => 'OnCalendar', 'interval' => $timer_interval }, ],
    }

}
