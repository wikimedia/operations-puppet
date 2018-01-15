# Prometheus machine metrics exporter. See also
# https://github.com/prometheus/node_exporter
#
# This class will also setup the 'textfile' collector to read metrics from
# /var/lib/prometheus/node.d/*.prom. The directory is writable by members of
# unix group 'prometheus-node-exporter', see also
# https://github.com/prometheus/node_exporter#textfile-collector

# === Parameters
#
# [*$ignored_devices*]
#  Regular expression to exclude block devices from being reported
#
# [*$collectors_extra*]
#  List of extra collectors to be enabled.
#
# [*$web_listen_address*]
#  IP:Port combination to listen on
#
#  Available collectors: (from "prometheus-node-exporter -collectors.print")
#  bonding diskstats filefd filesystem gmond interrupts ipvs lastlogin loadavg
#  mdadm megacli meminfo netdev netstat ntp runit sockstat stat supervisord
#  tcpstat textfile time uname


class prometheus::node_exporter (
    $ignored_devices  = "^(ram|loop|fd)\\\\d+\$",
    $ignored_fs_types  = "^(sys|proc|auto)fs$",
    $ignored_mount_points  = "^/(sys|proc|dev)($|/)",
    $collectors_extra = [],
    $web_listen_address = ':9100',
) {
    require_package('prometheus-node-exporter')
    validate_re($web_listen_address, ':\d+$')

    $collectors_default = ['conntrack', 'diskstats', 'entropy', 'edac', 'filefd', 'filesystem', 'hwmon',
        'loadavg', 'mdadm', 'meminfo', 'netdev', 'netstat', 'sockstat', 'stat', 'tcpstat',
        'textfile', 'time', 'uname', 'vmstat']
    $textfile_directory = '/var/lib/prometheus/node.d'
    $collectors_enabled = join(sort(concat($collectors_default, $collectors_extra)), ',')

    # members of this group are able to publish metrics
    # via the 'textfile' collector by writing files to $textfile_directory.
    # prometheus-node-exporter will export all files matching *.prom
    group { 'prometheus-node-exporter':
        ensure => present,
    }

    file { $textfile_directory:
        ensure  => directory,
        mode    => '0770',
        owner   => 'prometheus',
        group   => 'prometheus-node-exporter',
        require => [Package['prometheus-node-exporter'],
                    Group['prometheus-node-exporter']],
    }

    file { '/etc/default/prometheus-node-exporter':
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('prometheus/etc/default/prometheus-node-exporter.erb'),
        notify  => Service['prometheus-node-exporter'],
    }

    base::service_unit { 'prometheus-node-exporter':
        ensure           => present,
        refresh          => true,
        systemd_override => init_template('prometheus-node-exporter', 'systemd_override'),
        upstart          => upstart_template('prometheus-node-exporter'),
        require          => Package['prometheus-node-exporter'],
    }
}
