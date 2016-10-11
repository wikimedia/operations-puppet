# setup rsync to copy home dirs for server upgrade
class role::statistics::migration {

    $sourceip='10.64.21.101'

    ferm::service { 'stat-migration-rsync':
        proto  => 'tcp',
        port   => '873',
        srange => "${sourceip}/32",
    }

    include rsync::server

    file { [
        '/srv/stat1001',
        '/srv/stat1001/home',
        '/srv/stat1001/var',
        '/srv/stat1001/var/www',
        '/srv/stat1001/srv',
    ]:
        ensure => 'directory',
    }

    rsync::server::module { 'home':
        path        => '/srv/stat1001/home',
        read_only   => 'no',
        hosts_allow => $sourceip,
    }

    rsync::server::module { 'varwww':
        path        => '/srv/stat1001/var/www',
        read_only   => 'no',
        hosts_allow => $sourceip,
    }

    rsync::server::module { 'srv':
        path        => '/srv/stat1001/srv',
        read_only   => 'no',
        hosts_allow => $sourceip,
    }
}
