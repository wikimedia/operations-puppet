# sets up an rsyncd to copy people's home dirs
# during a server upgrade/migration
class role::microsites::peopleweb::migration {

    $sourceip='10.64.32.13'

    ferm::service { 'peopleweb-migration-rsync':
        proto  => 'tcp',
        port   => '873',
        srange => "${sourceip}/32",
    }

    include rsync::server

    rsync::server::module { 'people-homes':
        path        => '/home',
        read_only   => 'no',
        hosts_allow => $sourceip,
    }

}

