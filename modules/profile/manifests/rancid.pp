# Really Awful Notorious CIsco config Differ
class profile::rancid (
    Stdlib::Fqdn        $active_server   = lookup('netmon_server'),
    Array[Stdlib::Fqdn] $passive_servers = lookup('netmon_servers_failover'),
){

    class { '::rancid':
        active_server => $active_server,
    }

    backup::set { 'rancid': }

    $passive_servers.each |Stdlib::Fqdn $passive_server| {
        rsync::quickdatacopy { "var-lib-rancid-${passive_server}":
            ensure              => present,
            auto_sync           => false,
            source_host         => $active_server,
            dest_host           => $passive_server,
            module_path         => '/var/lib/rancid',
            server_uses_stunnel => true,
            chown               => 'rancid:rancid',
        }
    }

    # TODO: clean up after T309074
    rsync::quickdatacopy { 'var-lib-rancid':
        ensure      => absent,
        source_host => 'netmon1002.wikimedia.org',
        dest_host   => 'netmon2001.wikimedia.org',
        module_path => '/var/lib/rancid',
    }

    profile::contact { $title:
        contacts => ['ayounsi']
    }
}
