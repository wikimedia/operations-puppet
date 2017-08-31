class smart::init {
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
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0544',
        source => "puppet:///modules/${module_name}/20logger",
    }

    file { '/usr/local/sbin/smart-data-dump':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0544',
        source => "puppet:///modules/${module_name}/smart-data-dump",
    }
}
