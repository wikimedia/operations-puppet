# Really Awful Notorious CIsco config Differ
class profile::rancid (
    Stdlib::Fqdn $active_server  = lookup('netmon_server'),
    Stdlib::Fqdn $passive_server = lookup('netmon_server_failover'),
){

    class { '::rancid':
        active_server => $active_server,
    }

    backup::set { 'rancid': }

    rsync::quickdatacopy { 'var-lib-rancid':
      ensure              => present,
      auto_sync           => false,
      source_host         => $active_server,
      dest_host           => $passive_server,
      module_path         => '/var/lib/rancid',
      server_uses_stunnel => true,
    }
    profile::contact { $title:
        contacts => ['ayounsi']
    }
}
