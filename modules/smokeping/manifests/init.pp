class smokeping {

    require_package('smokeping', 'curl', 'dnsutils')

    file { '/etc/smokeping/config.d':
        ensure  => directory,
        recurse => true,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/smokeping/config.d',
        require => Package['smokeping'],
    }

    service { 'smokeping':
        ensure    => running,
        require   => [
            Package['smokeping'],
            File['/etc/smokeping/config.d'],
        ],
        subscribe => File['/etc/smokeping/config.d'],
    }


    $sourceip='208.80.154.159'

    ferm::service { 'smokeping-migration-rsync':
        ensure => present,
        proto  => 'tcp',
        port   => '873',
        srange => "${sourceip}/32",
    }

    include rsync::server

    rsync::server::module { 'smokeping_data':
        ensure      => present,
        path        => '/var/lib/smokeping',
        read_only   => 'no',
        hosts_allow => $sourceip,
    }
}
