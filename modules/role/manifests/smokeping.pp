# http://oss.oetiker.ch/smokeping/
class role::smokeping {

    system::role { 'smokeping': description => 'smokeping server' }

    include ::smokeping
    include ::smokeping::web

    ferm::service { 'smokeping-http':
        proto  => 'tcp',
        port   => '80',
        srange => '$CACHE_MISC',
    }

    backup::set {'smokeping': }

    rsync::quickdatacopy { 'var-lib-smokeping':
        ensure      => present,
        auto_sync   => false,
        source_host => 'netmon2001.wikimedia.org',
        dest_host   => 'netmon1002.wikimedia.org',
        module_path => '/var/lib/smokeping',
    }
}
