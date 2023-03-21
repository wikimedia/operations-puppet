# SPDX-License-Identifier: Apache-2.0
# @summary Prometheus exporter for mcrouter server metrics.
#          Works only on bullseye+ as the package isn't around in buster
# @param config_file location of the ipmi exporter config file
# @param collectors the collectors to export
# @param exclude_sensor_ids list of sensor ID's to exclude
class prometheus::ipmi_exporter (
    Stdlib::Unixpath                            $config_file        = '/etc/prometheus/ipmi_exporter.yml',
    Array[Integer[1,255]]                       $exclude_sensor_ids = [],
    Array[Prometheus::Ipmi_exporter::Collector] $collectors         = ['bmc', 'ipmi', 'chassis', 'dcmi', 'sel'],
) {
    # prometheus-ipmi-exporter depends already on freeipmi-tools package, no
    # need to care for it specifically
    ensure_packages('prometheus-ipmi-exporter')

    # Granting sudo privileges for specific commands to the exporter
    sudo::user { 'prometheus_ipmi_exporter':
        user       => 'prometheus',
        privileges => [
            'ALL = NOPASSWD: /usr/sbin/ipmimonitoring',
            'ALL = NOPASSWD: /usr/sbin/ipmi-sensors',
            'ALL = NOPASSWD: /usr/sbin/ipmi-dcmi',
            'ALL = NOPASSWD: /usr/sbin/ipmi-raw',
            'ALL = NOPASSWD: /usr/sbin/bmc-info',
            'ALL = NOPASSWD: /usr/sbin/ipmi-chassis',
            'ALL = NOPASSWD: /usr/sbin/ipmi-sel',
        ],
    }

    # TODO: Remove this entire wrapper hack once we are on 1.4.0+
    $prometheus_home = '/var/lib/prometheus'
    # Provide a wrapper around sudo to allow the exporter to execute
    # freeipmi-tools
    # ipmi_sudo.yml file
    file { "${prometheus_home}/ipmi_sudo_wrapper.sh":
        ensure  => file,
        mode    => '0555',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/prometheus/ipmi_exporter/ipmi_sudo_wrapper.sh',
        require => Sudo::User['prometheus_ipmi_exporter'],
    }
    # Instruct the exporter to use our wrapper for freeipmi utilities
    $args = {
        'web.listen-address' => "${facts['networking']['ip']}:9290",
        'freeipmi.path'      => $prometheus_home,
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
    # Create symlinks for our wrapper for every tool
    file { [
        "${prometheus_home}/ipmimonitoring",
        "${prometheus_home}/ipmi-sensors",
        "${prometheus_home}/ipmi-dcmi",
        "${prometheus_home}/bmc-info",
        "${prometheus_home}/ipmi-chassis",
        "${prometheus_home}/ipmi-sel",
        ]:
        ensure => link,
        owner  => 'prometheus',
        group  => 'prometheus',
        target => "${prometheus_home}/ipmi_sudo_wrapper.sh",
    }

    $config = {
        'modules' => {
            'default'            => $collectors,
            'exclude_sensor_ids' => $exclude_sensor_ids,
        },
    }
    file { $config_file:
        ensure  => file,
        mode    => '0444',
        content => $config.to_yaml,
        notify  => Service['prometheus-ipmi-exporter'],
    }
    # NOTE: We can't use this file before we upgrade to 1.4.0, but add it anyway
    # to not reinvent it later on
    file { '/etc/prometheus/ipmi_sudo.yml':
        ensure  => file,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/prometheus/ipmi_exporter/ipmi_sudo.yml',
        notify  => Service['prometheus-ipmi-exporter'],
        require => Sudo::User['prometheus_ipmi_exporter'],
    }

    service { 'prometheus-ipmi-exporter':
        ensure  => running,
        require => Package['prometheus-ipmi-exporter'],
    }

    profile::auto_restarts::service { 'prometheus-ipmi-exporter': }
}
