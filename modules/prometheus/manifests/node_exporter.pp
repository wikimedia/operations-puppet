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
#  Available collectors: (from "prometheus-node-exporter -collectors.print")
#  bonding diskstats filefd filesystem gmond interrupts ipvs lastlogin loadavg
#  mdadm megacli meminfo netdev netstat ntp runit sockstat stat supervisord
#  tcpstat textfile time uname


class prometheus::node_exporter (
    $ignored_devices  = '^(ram|loop|fd)\\d+$',
    $collectors_extra = [],
) {
    requires_os('debian >= jessie')

    require_package('prometheus-node-exporter')

    $collectors_default = ['diskstats', 'filefd', 'filesystem', 'loadavg',
        'mdadm', 'meminfo', 'netdev', 'netstat', 'sockstat', 'stat',
        'textfile', 'time', 'uname']
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
        mode    => '0470',
        owner   => 'root',
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
        ensure  => present,
        refresh => true,
        systemd => true,
        upstart => true,
        require => Package['prometheus-node-exporter'],
    }
}
