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
# [*$ignored_fs_types*]
#  Regular expression to exclude filesystem types from being reported
#
# [*$ignored_mount_points*]
#  Regular expression to exclude mount points from being reported
#
# [*$netstat_fields*]
#  Regular expression of netstat fields to include
#
# [*vmstat_fields*]
#  Regular expression of vmstat fields to include
#
# [*$collectors_extra*]
#  List of extra collectors to be enabled.
#
# [*$web_listen_address*]
#  IP:Port combination to listen on
#
#  Available collectors: https://github.com/prometheus/node_exporter/tree/v0.17.0#collectors


class prometheus::node_exporter (
    String $ignored_devices  = '^(ram|loop|fd|(h|s|v|xv)d[a-z]|nvme[0-9]+n[0-9]+p)[0-9]+$',
    String $ignored_fs_types  = '^(overlay|autofs|binfmt_misc|cgroup|configfs|debugfs|devpts|devtmpfs|fusectl|hugetlbfs|mqueue|nsfs|proc|procfs|pstore|rpc_pipefs|securityfs|sysfs|tracefs)$',
    String $ignored_mount_points  = '^/(sys|proc|dev|var/lib/docker|var/lib/kubelet)($|/)',
    String $netstat_fields = '^(.*)',
    String $vmstat_fields = '^(.*)',
    Array[String] $collectors_extra = [],
    String $collector_ntp_server = '127.0.0.1',
    Pattern[/:\d+$/] $web_listen_address = ':9100',
) {
    $collectors_default = ['buddyinfo', 'conntrack', 'diskstats', 'entropy', 'edac', 'filefd', 'filesystem', 'hwmon',
        'loadavg', 'mdadm', 'meminfo', 'netdev', 'netstat', 'sockstat', 'stat', 'tcpstat',
        'textfile', 'time', 'uname', 'vmstat']
    $textfile_directory = '/var/lib/prometheus/node.d'

    package { 'prometheus-node-exporter':
      ensure => 'present'
    }

    # Configuration compatibile less than 0.16
    # TODO: remove after Trusty is gone.
    if ($::lsbdistcodename == 'trusty') {
        $collectors_enabled = join(sort(concat($collectors_default, $collectors_extra)), ',')

        file { '/etc/default/prometheus-node-exporter':
            ensure  => present,
            mode    => '0444',
            owner   => 'root',
            group   => 'root',
            content => template('prometheus/etc/default/prometheus-node-exporter.erb'),
            notify  => Service['prometheus-node-exporter'],
        }
    }
    # New configuration style (0.16+)
    else {
        $collectors_enabled = concat($collectors_default, $collectors_extra)

        file { '/etc/default/prometheus-node-exporter':
              ensure  => present,
              mode    => '0444',
              owner   => 'root',
              group   => 'root',
              content => template('prometheus/etc/default/prometheus-node-exporter-0.17.erb'),
              notify  => Service['prometheus-node-exporter'],
        }

        # Disabled because broken (https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=922803)
        service { 'prometheus-node-exporter-ipmitool-sensor.timer':
            ensure   => 'stopped',
            provider => 'systemd',
            enable   => 'mask',
            require  => Package['prometheus-node-exporter'],
        }

        # Disabled in favor of internal smart module (smart-data-dump.py)
        service { 'prometheus-node-exporter-smartmon.timer':
            ensure   => 'stopped',
            provider => 'systemd',
            enable   => 'mask',
            require  => Package['prometheus-node-exporter'],
        }
    }

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

    base::service_unit { 'prometheus-node-exporter':
        ensure           => present,
        refresh          => true,
        systemd_override => init_template('prometheus-node-exporter', 'systemd_override'),
        require          => Package['prometheus-node-exporter'],
    }

    base::service_auto_restart { 'prometheus-node-exporter': }
}
