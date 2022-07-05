# SPDX-License-Identifier: Apache-2.0
class smart (
    $ensure = present,
) {
    ensure_packages(['python3-prometheus-client', 'bsdutils'])

    $outfile = '/var/lib/prometheus/node.d/device_smart.prom'

    if $facts['is_virtual'] {
        fail('smart module is not supported on virtual hosts')
    }

    package { 'smartmontools':
        ensure => $ensure,
    }

    # smartd doesn't support enumerating devices on cciss/hpsa controllers and
    # fails to start. Since alerting is done via metrics from smart-data-dump,
    # mask smartd when needed. See also T246997.
    if debian::codename::ge('buster') and 'hpsa' in $facts['raid'] {
        systemd::mask { 'smartd.service': }
    } else {
        profile::auto_restarts::service { 'smartd': }
    }

    # Make sure we send smart alerts from smartd via syslog and not email.
    file { '/etc/smartmontools/run.d/10mail':
        ensure  => absent,
        require => Package['smartmontools'],
    }

    file { '/etc/smartmontools/run.d/20logger':
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0544',
        source  => "puppet:///modules/${module_name}/20logger",
        require => Package['smartmontools'],
    }

    file { '/usr/local/sbin/smart-data-dump':
        ensure => $ensure,
        owner  => 'root',
        group  => 'root',
        mode   => '0544',
        source => "puppet:///modules/${module_name}/smart_data_dump.py",
    }

    $minute = fqdn_rand(60, 'export_smart_data_dump')
    systemd::timer::job { 'export_smart_data_dump':
        ensure      => $ensure,
        user        => 'root',
        description => 'Collect SMART information from all physical disks and report as Prometheus metrics',
        command     => "/usr/local/sbin/smart-data-dump --syslog --outfile ${outfile}",
        interval    => {
            'start'    => 'OnCalendar',
            'interval' => "*-*-* *:${minute}:00",
        },
        require     => File['/usr/local/sbin/smart-data-dump'],
    }

    # Cleanup outfile only on ensure=absent, since on ensure=present the file gets created by cron.
    if $ensure == absent {
      file { $outfile:
          ensure => $ensure,
      }
    }
}
