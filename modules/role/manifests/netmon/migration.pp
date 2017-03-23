# temp. role to copy netmon1001 data for migration
class role::netmon::migration {

    $sourceip='208.80.154.159'

    ferm::service { 'netmon-migration-rsync':
        proto  => 'tcp',
        port   => '873',
        srange => "${sourceip}/32",
    }

    include rsync::server

    file { [ '/srv/netmon1001',
             '/srv/netmon1001/librenms',
             '/srv/netmon1001/smokeping',
             '/srv/netmon1001/torrus' }:
        ensure => 'directory',
    }

    rsync::server::module { 'librenms':
        path        => '/srv/netmon1001/librenms',
        read_only   => 'no',
        hosts_allow => $sourceip,
    }

    rsync::server::module { 'smokeping':
        path        => '/srv/netmon1001/smokeping',
        read_only   => 'no',
        hosts_allow => $sourceip,
    }

    rsync::server::module { 'torrus':
        path        => '/srv/netmon1001/torrus',
        read_only   => 'no',
        hosts_allow => $sourceip,
    }
}
