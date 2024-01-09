# sync MediaWiki private files between releases* servers
class profile::releases::mediawiki::private (
    Stdlib::Fqdn $deployment_server = lookup('deployment_server'),
    Stdlib::Fqdn $primary_server = lookup('releases_server'),
    Array[Stdlib::Fqdn] $secondary_servers = lookup('releases_servers_failover'),
){

    # server-agnostic rsync on the primary releases server
    rsync::quickdatacopy { 'srv-mediawiki-private-primary':
        ensure      => present,
        auto_sync   => false,
        delete      => true,
        source_host => $deployment_server,
        dest_host   => $primary_server,
        module_path => '/srv/mediawiki-staging/private',
    }

    # if the primary changes, absent the hostname-based rsync
    rsync::quickdatacopy { "srv-mediawiki-private-${primary_server}":
        ensure      => absent,
        auto_sync   => false,
        delete      => true,
        source_host => $deployment_server,
        dest_host   => $primary_server,
        module_path => '/srv/mediawiki-staging/private',
    }

    $secondary_servers.each |Stdlib::Fqdn $secondary_server| {
        unless $deployment_server == $secondary_server {
            rsync::quickdatacopy { "srv-mediawiki-private-${secondary_server}":
                ensure      => present,
                auto_sync   => false,
                delete      => true,
                source_host => $deployment_server,
                dest_host   => $secondary_server,
                module_path => '/srv/mediawiki-staging/private',
            }
        }
    }
  }
