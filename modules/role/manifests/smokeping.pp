# http://oss.oetiker.ch/smokeping/
class role::smokeping {

    system::role { 'smokeping': description => 'smokeping server' }

    $active_server = hiera('netmon_server')

    rsync::quickdatacopy { 'var-lib-smokeping':
        ensure      => present,
        auto_sync   => true,
        source_host => $active_server,
        dest_host   => $::fqdn,
        module_path => '/var/lib/smokeping',
    }

    ferm::service { 'smokeping-http':
        proto  => 'tcp',
        port   => '80',
        srange => '$CACHE_MISC',
    }

    backup::set { 'smokeping': }

    class{ '::smokeping':
        active_server => $active_server,
    }

    class{ '::smokeping::web': }
}
