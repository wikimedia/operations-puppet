class profile::releases::common(
    Stdlib::Fqdn $sitename = lookup('profile::releases::mediawiki::sitename'),
    Stdlib::Host $deployment_server = lookup('deployment_server'),
    Stdlib::Fqdn $active_server = lookup('releases_server'),
    Array[Stdlib::Fqdn] $secondary_servers = lookup('releases_servers_failover'),
    String $server_admin = lookup('profile::releases::mediawiki::server_admin'),
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
          delete      => true,
          source_host => $active_server,
          dest_host   => $secondary_server,
          module_path => '/srv/org/wikimedia/releases',
        }
    }

    class { '::httpd':
        modules => ['rewrite', 'headers', 'proxy', 'proxy_http'],
    }

    httpd::site { $sitename:
        content => template('releases/apache.conf.erb'),
    }

    monitoring::service { 'https_releases':
        description   => "HTTPS ${sitename}",
        check_command => "check_https_url!${sitename}!/",
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Releases.wikimedia.org',
    }

    ferm::service { 'releases_http':
        proto  => 'tcp',
        port   => '80',
        srange => "(${::ipaddress} ${::ipaddress6})",
    }

    ferm::service { 'releases_http_deployment_cumin':
        proto  => 'tcp',
        port   => '80',
        srange => '($DEPLOYMENT_HOSTS $CUMIN_MASTERS)',
    }

    backup::set { 'srv-org-wikimedia': }
}
