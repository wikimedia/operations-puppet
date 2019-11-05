# http://oss.oetiker.ch/smokeping/
class profile::smokeping (
    $active_server = hiera('netmon_server'),
    $passive_server = hiera('netmon_server_failover'),
){

    class{ '::smokeping':
        active_server => $active_server,
    }

    class{ '::smokeping::web': }

    rsync::quickdatacopy { 'var-lib-smokeping':
        ensure              => present,
        auto_sync           => true,
        source_host         => $active_server,
        dest_host           => $passive_server,
        module_path         => '/var/lib/smokeping',
        server_uses_stunnel => true,  # testing for T237424
    }

    ferm::service { 'smokeping-http':
        proto  => 'tcp',
        port   => '80',
        srange => '$CACHES',
    }

    backup::set { 'smokeping': }
}
