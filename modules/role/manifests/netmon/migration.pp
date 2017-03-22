# temp. role to copy netmon1001 data for migration
class role::netmon::migration {

    $sourceip='208.80.154.159'

    ferm::service { 'netmon-migration-rsync':
        proto  => 'tcp',
        port   => '873',
        srange => "${sourceip}/32",
    }

    include rsync::server

    file { '/srv/netmon1001':
        ensure => 'directory',
    }

    rsync::server::module { 'people-homes':
        path        => '/srv/netmon1001',
        read_only   => 'no',
        hosts_allow => $sourceip,
    }
}
