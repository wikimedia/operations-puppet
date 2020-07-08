# https://releases.wikimedia.org/mediawiki
# sync MediaWiki security patches between releases* servers
class profile::releases::mediawiki::security (
    Stdlib::Fqdn $deployment_server = lookup('deployment_server'),
    Array[Stdlib::Fqdn] $secondary_servers = lookup('releases_servers_failover'),
){

    $secondary_servers.each |String $secondary_server| {
        rsync::quickdatacopy { "srv-patches-${secondary_server}":
            ensure      => present,
            auto_sync   => true,
            source_host => $deployment_server,
            dest_host   => $secondary_server,
            module_path => '/srv/patches',
        }
    }
}
