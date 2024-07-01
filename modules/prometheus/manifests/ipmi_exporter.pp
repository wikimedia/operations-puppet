# SPDX-License-Identifier: Apache-2.0
# @summary Prometheus exporter for ipmi server metrics.
# @param config_file location of the ipmi exporter config file
# @param collectors the collectors to export
# @param exclude_sensor_ids list of sensor ID's to exclude
class prometheus::ipmi_exporter (
    Stdlib::Unixpath                            $config_file        = '/etc/prometheus/ipmi_exporter.yml',
    Array[Integer[1,255]]                       $exclude_sensor_ids = [],
    Array[Prometheus::Ipmi_exporter::Collector] $collectors         = ['bmc', 'ipmi', 'chassis', 'dcmi', 'sel', 'sel-events'],
) {
    # prometheus-ipmi-exporter depends already on freeipmi-tools package, no
    # need to care for it specifically
    ensure_packages('prometheus-ipmi-exporter')

    # Maps the collector name to the binary to execute
    $collector_maps = {
        'bmc'        => 'bmc-info',
        'ipmi'       => 'ipmimonitoring',
        'chassis'    => 'ipmi-chassis',
        'dcmi'       => 'ipmi-dcmi',
        'sel'        => 'ipmi-sel',
        'sel-events' => 'ipmi-sel',
    }

    $privileges = ($collector_maps.values + ['ipmi-sensors', 'ipmi-raw']).map |$cmd| {
        "ALL = NOPASSWD: /usr/sbin/${cmd}"
    }
    # Granting sudo privileges for specific commands to the exporter
    sudo::user { 'prometheus_ipmi_exporter':
        user       => 'prometheus',
        privileges => $privileges,
        before     => Package['prometheus-ipmi-exporter'],
    }

    $args = {
        # The debian packages force this to use /usr/sbin instead of path
        # however as we uses sudo we need the path to be /usr/bin
        'freeipmi.path'      => '/usr/bin',
        'web.listen-address' => "${facts['networking']['ip']}:9290",
        'config.file'        => $config_file,
    }.wmflib::argparse('', '=')

    file { '/etc/default/prometheus-ipmi-exporter':
        ensure  => file,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => "ARGS=\"${args}\"",
        notify  => Service['prometheus-ipmi-exporter'],
    }

    $config = {
        'modules' => {
            'default'            => {
                'collectors'         => $collectors,
                'exclude_sensor_ids' => $exclude_sensor_ids,
                'collector_cmd'      => Hash($collector_maps.keys.map |$key| { [$key, 'sudo'] }),
                'custom_args'        => Hash($collector_maps.map |$key, $cmd| { [$key, [$cmd]] }),
            },
        },
    }
    file { $config_file:
        ensure  => file,
        mode    => '0444',
        content => $config.to_yaml,
        require => Package['prometheus-ipmi-exporter'],
        notify  => Service['prometheus-ipmi-exporter'],
    }

    service { 'prometheus-ipmi-exporter':
        ensure  => running,
        require => Package['prometheus-ipmi-exporter'],
    }

    profile::auto_restarts::service { 'prometheus-ipmi-exporter': }
}
