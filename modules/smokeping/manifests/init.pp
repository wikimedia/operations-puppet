class smokeping {
    system::role { 'smokeping': description => 'Smokeping' }

    include config

    package { 'smokeping':
        ensure => present;
    }

    package { 'curl':
        ensure => present;
    }

    service { 'smokeping':
        ensure    => running,
        require   => [ Package['smokeping'], File['/etc/smokeping/config.d'] ],
        subscribe => File['/etc/smokeping/config.d'],
    }
}
