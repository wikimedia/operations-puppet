# https://releases.wikimedia.org/mediawiki
# sync MediaWiki security patches between releases* servers
# from the deployment server
class profile::releases::mediawiki::security (
    Stdlib::Fqdn $deployment_server = lookup('deployment_server'),
    Stdlib::Fqdn $primary_server = lookup('releases_server'),
    Array[Stdlib::Fqdn] $secondary_servers = lookup('releases_servers_failover'),
){

    # server-agnostic rsync on the primary releases server
    rsync::quickdatacopy { 'srv-patches-releases-primary':
        ensure                     => present,
        auto_sync                  => true,
        delete                     => true,
        source_host                => $deployment_server,
        dest_host                  => $primary_server,
        module_path                => '/srv/patches',
        chown                      => 'jenkins:705',
        ignore_missing_file_errors => true,
    }

    # if the primary changes, absent the hostname-based rsync
    rsync::quickdatacopy { "srv-patches-${primary_server}":
        ensure                     => absent,
        auto_sync                  => true,
        delete                     => true,
        source_host                => $deployment_server,
        dest_host                  => $primary_server,
        module_path                => '/srv/patches',
        ignore_missing_file_errors => true,
    }

    $secondary_servers.each |Stdlib::Fqdn $secondary_server| {
        unless $deployment_server == $secondary_server {
            rsync::quickdatacopy { "srv-patches-${secondary_server}":
                ensure                     => present,
                auto_sync                  => true,
                delete                     => true,
                source_host                => $deployment_server,
                dest_host                  => $secondary_server,
                module_path                => '/srv/patches',
                chown                      => 'jenkins:705',
                ignore_missing_file_errors => true,
            }
        }
    }
}
