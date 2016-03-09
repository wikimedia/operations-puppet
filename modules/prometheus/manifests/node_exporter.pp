class prometheus::node_exporter (
    $ignored_devices  = '^(ram|loop|fd)\\d+$',
    $collectors_extra = [],
) {
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
        content => "ARGS='-collector.diskstats.ignored-devices=${ignored_devices} -collector.textfile.directory=${textfile_directory} -collectors.enabled=${collectors_enabled}'",
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
