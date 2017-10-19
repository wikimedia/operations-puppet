class smart {
    require_package(['python3-prometheus-client', 'python3', 'bsdutils'])

    $outfile = '/var/lib/prometheus/node.d/device_smart.prom'

    if $facts['is_virtual'] == true {
        fail('smart module is not supported on virtual hosts')
    }

    # Prefer smartmontools version from backports (if any) because of newer
    # smart drivedb.
    package { 'smartmontools':
        ensure          => installed,
        install_options => ['-t', "${::lsbdistcodename}-backports"],
    }

    # Make sure we send smart alerts from smartd via syslog and not email.
    file { '/etc/smartmontools/run.d/10mail':
        ensure  => absent,
        require => Package['smartmontools'],
    }

    file { '/etc/smartmontools/run.d/20logger':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0544',
        source  => "puppet:///modules/${module_name}/20logger",
        require => Package['smartmontools'],
    }

    file { '/usr/local/sbin/smart-data-dump':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0544',
        source => "puppet:///modules/${module_name}/smart-data-dump",
    }

    cron { 'export_smart_data_dump':
        command => "/usr/local/sbin/smart-data-dump --outfile $outfile"
        user    => 'root',
        hour    => '*',
        minute  => fqdn_rand(60, 'export_smart_data_dump'),
        require => File['/usr/local/sbin/smart-data-dump'],
    }
}
