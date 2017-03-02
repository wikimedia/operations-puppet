# setup rsync to copy home dirs for server upgrade
class role::bastionhost::migration {

    $sourceip='91.198.174.112' # bast3001

    ferm::service { 'bast-home-rsync':
        proto  => 'tcp',
        port   => '873',
        srange => "${sourceip}/32",
    }

    include ::rsync::server

    file { [ '/srv/bast3001', '/srv/bast3001/home' ]:
        ensure => 'directory',
    }

    rsync::server::module { 'home':
        path        => '/srv/bast3001/home',
        read_only   => 'no',
        hosts_allow => $sourceip,
    }

}
