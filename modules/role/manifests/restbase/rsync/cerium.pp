# rsync cassandra data from cerium to restbase-test machines
class role::restbase::rsync::cerium {

    $sourceip='10.64.16.147' # cerium.eqiad.wmnet

    $basepath='/srv/backups/eqiad/local_group_wikipedia_T_parsoid_'

    file { [ '/srv/backups', '/srv/backups/eqiad', ]:
        ensure => directory,
    }

    ferm::service { 'restbase-rsync-cerium':
        proto  => 'tcp',
        port   => '873',
        srange => "${sourceip}/32",
    }

    include rsync::server

    rsync::server::module { 'parsoid-html':
        path        => "${basepath}_html/data-f3c38310f28b11e4852cad59d68785c5/snapshots/1469551242786/",
        read_only   => 'no',
        hosts_allow => $sourceip,
    }

    rsync::server::module { 'parsoid-data':
        path        => "${basepath}_dataW4ULtxs1oMqJ/data-f5269580f28b11e4a47df15be73644e3/snapshots/1469551242786/",
        read_only   => 'no',
        hosts_allow => $sourceip,
    }

    rsync::server::module { 'parsoid-section':
        path        => "${basepath}_section_offsets/data-9ec361001b7b11e59825ad59d68785c5/snapshots/1469551242786/",
        read_only   => 'no',
        hosts_allow => $sourceip,
    }
}
