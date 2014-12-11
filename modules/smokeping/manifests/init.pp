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
        ensure    => running,
        require   => [ Package['smokeping'], File['/etc/smokeping/config.d'] ],
        subscribe => File['/etc/smokeping/config.d'],
    }
}
