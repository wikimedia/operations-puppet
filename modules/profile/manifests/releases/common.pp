class profile::releases::common(
    Stdlib::Fqdn $active_server = lookup('releases_server'),
    Array[Stdlib::Fqdn] $secondary_servers = lookup('releases_servers_failover'),
){

    # T205037
    $motd_ensure = mediawiki::state('primary_dc') ? {
        $::site => 'absent',
        default => 'present',
    }

    motd::script { 'rsync_source_warning':
        ensure   => $motd_ensure,
        priority => 1,
        content  => template('role/releases/rsync_source_warning.motd.erb'),
    }

    base::service_auto_restart { 'rsync': }

    $secondary_servers.each |String $secondary_server| {
        rsync::quickdatacopy { "srv-org-wikimedia-releases-${secondary_server}":
          ensure      => present,
          auto_sync   => true,
          source_host => $active_server,
          dest_host   => $secondary_server,
          module_path => '/srv/org/wikimedia/releases',
        }
    }
}
