# setup rsync to copy home dirs for server upgrade
class role::bastionhost::migration {

    $sourceip='10.64.0.22' # tungsten

    ferm::service { 'bast-home-rsync':
        proto  => 'tcp',
        port   => '873',
        srange => "${sourceip}/32",
    }

    include ::rsync::server

    file { [ '/srv/bast1001', '/srv/bast1001/home' ]:
        ensure => 'directory',
    }

    rsync::server::module { 'home':
        path        => '/srv/bast1001/home',
        read_only   => 'no',
        hosts_allow => $sourceip,
    }

}
