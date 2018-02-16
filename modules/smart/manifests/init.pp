class smart (
    $ensure = present,
) {
    require_package(['python3-prometheus-client', 'bsdutils'])

    $outfile = '/var/lib/prometheus/node.d/device_smart.prom'

    if $facts['is_virtual'] == true {
        fail('smart module is not supported on virtual hosts')
    }

    # Prefer smartmontools version from backports (on Debian, if any) because of newer smart
    # drivedb.
    if os_version('debian >= jessie') {
        apt::pin { 'smartmontools_backports':
            pin      => "release a=${::lsbdistcodename}-backports",
            priority => '1001',
            before   => Package['smartmontools'],
        }
    }

    package { 'smartmontools':
        ensure => $ensure,
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
        source => "puppet:///modules/${module_name}/smart-data-dump",
    }

    cron { 'export_smart_data_dump':
        ensure  => $ensure,
        command => "/usr/local/sbin/smart-data-dump --outfile ${outfile}",
        user    => 'root',
        hour    => '*',
        minute  => fqdn_rand(60, 'export_smart_data_dump'),
        require => File['/usr/local/sbin/smart-data-dump'],
    }

    # Cleanup outfile only on ensure=absent, since on ensure=present the file gets created by cron.
    if $ensure == absent {
      file { $outfile:
          ensure => $ensure,
      }
    }
}
