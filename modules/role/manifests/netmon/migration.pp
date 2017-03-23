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
            '/srv/netmon1001/librenms/var',
            '/srv/netmon1001/librenms/var/lib',
            '/srv/netmon1001/librenms/var/lib/librenms',
            '/srv/netmon1001/smokeping',
            '/srv/netmon1001/smokeping/var',
            '/srv/netmon1001/smokeping/var/lib',
            '/srv/netmon1001/smokeping/var/lib/smokeping',
            '/srv/netmon1001/smokeping/var/cache',
            '/srv/netmon1001/smokeping/var/cache/smokeping',
            '/srv/netmon1001/torrus',
            '/srv/netmon1001/torrus/var',
            '/srv/netmon1001/torrus/var/cache',
            '/srv/netmon1001/torrus/var/cache/torrus',
            '/srv/netmon1001/torrus/var/lib',
            '/srv/netmon1001/torrus/var/lib/torrus', ]:
        ensure => 'directory',
    }

    rsync::server::module { 'librenms-lib':
        path        => '/srv/netmon1001/librenms/var/lib/librenms',
        read_only   => 'no',
        hosts_allow => $sourceip,
    }

    rsync::server::module { 'smokeping-lib':
        path        => '/srv/netmon1001/smokeping/var/lib/smokeping',
        read_only   => 'no',
        hosts_allow => $sourceip,
    }

    rsync::server::module { 'smokeping-cache':
        path        => '/srv/netmon1001/smokeping/var/cache/smokeping',
        read_only   => 'no',
        hosts_allow => $sourceip,
    }

    rsync::server::module { 'torrus-lib':
        path        => '/srv/netmon1001/torrus/var/lib/torrus',
        read_only   => 'no',
        hosts_allow => $sourceip,
    }

    rsync::server::module { 'torrus-cache':
        path        => '/srv/netmon1001/torrus/var/cache/torrus',
        read_only   => 'no',
        hosts_allow => $sourceip,
    }
}
