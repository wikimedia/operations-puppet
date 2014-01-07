class smokeping {
    system::role { 'smokeping': description => 'Smokeping' }

    include config

    package { 'smokeping':
        ensure => latest;
    }

    package { 'curl':
        ensure => latest;
    }

    service { 'smokeping':
        require => [ Package['smokeping'], File['/etc/smokeping/config.d'] ],
        subscribe => File['/etc/smokeping/config.d'],
        ensure => running;
    }
}
