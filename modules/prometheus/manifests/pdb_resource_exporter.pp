# SPDX-License-Identifier: Apache-2.0
# @summary prometheus::pdb_resource_exporter define. It pushes stats about puppetdb resources to pushgateway.
# @param ensure If set to 'present', the exporter will be installed and the timer will be activated
# @param time_interval Timer frequency
# @param pushgateway_url Url of pushgateway instance
# @param config YAML structure listing the metrics to be exported
#
class prometheus::pdb_resource_exporter(
    Stdlib::HTTPUrl                           $pushgateway_url,
    Prometheus::Pdb_resource_exporter::Config $config,
    Wmflib::Ensure                            $ensure         = 'present',
    String                                    $timer_interval = 'hourly',
) {

    ensure_packages(['python3-click', 'python3-prometheus-client', 'jq'])

    file {
        default:
            ensure => file;
        '/etc/pdb-resource-exporter.yml':
            content => $config.wmflib::to_yaml,
            mode    => '0444';
        '/usr/local/bin/pdb-resource-exporter':
            source => 'puppet:///modules/prometheus/pdb_resource_exporter.py',
            mode   => '0555',
    }

    $timer_environment = {
            'PUSHGATEWAY_URL' => $pushgateway_url
        }

    systemd::timer::job { 'prometheus-pdb-resource-exporter':
        ensure        => $ensure,
        description   => 'Send puppetdb resources stats to promethues-pushgateway',
        user          => 'nobody',
        ignore_errors => true,
        environment   => $timer_environment,
        command       => '/usr/local/bin/pdb-resource-exporter',
        interval      => [ { 'start' => 'OnCalendar', 'interval' => $timer_interval }, ],
    }

}
