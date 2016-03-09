# Prometheus machine metrics exporter. See also
# https://github.com/prometheus/node_exporter
#
# This class will setup the 'textfile' collector to read metrics from
# /etc/prometheus/node.d/*.prom. The directory is writable by members of unix
# group 'prometheus-node-exporter', see also
# https://github.com/prometheus/node_exporter#textfile-collector

# === Parameters
#
# [*$ignored_devices*]
#  Regular expression to exclude block devices from being reported
#
# [*$collectors_extra*]
#  List of extra collectors to be enabled.

class prometheus::node_exporter (
    $ignored_devices  = '^(ram|loop|fd)\\d+$',
    $collectors_extra = [],
) {
    if ! os_version('debian >= jessie') {
        fail('Only Debian >= jessie supported now')
    }

    require_package('prometheus-node-exporter')

    $collectors_standard = ['diskstats', 'filesystem', 'loadavg', 'meminfo',
                            'stat', 'textfile', 'time', 'netdev', 'netstat']
    $textfile_directory = '/etc/prometheus/node.d'
    $collectors_enabled = join(concat($collectors_standard, $collectors_extra), ',')

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
        content => template('prometheus/etc/default/prometheus-node-exporter.erb')
        notify  => Service['prometheus-node-exporter'],
    }

    base::service_unit { 'prometheus-node-exporter':
        ensure  => present,
        refresh => true,
        systemd => true,
        upstart => true,
        require => Package['prometheus-node-exporter'],
    }

    ferm::service { 'prometheus-node-exporter':
        proto  => 'tcp',
        port   => '9100',
        srange => '$INTERNAL',
    }
}
