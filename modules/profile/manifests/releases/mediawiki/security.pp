# https://releases.wikimedia.org/mediawiki
# sync MediaWiki security patches between releases* servers
class profile::releases::mediawiki::security (
    Stdlib::Fqdn $deployment_server = lookup('deployment_server'),
    Stdlib::Fqdn $primary_server = lookup('releases_server'),
    Array[Stdlib::Fqdn] $secondary_servers = lookup('releases_servers_failover'),
){

    $all_secondary_servers = join($secondary_servers, ' ')
    $all_releases_servers = "${primary_server} ${all_secondary_servers}"
    $all_releases_servers_array = split($all_releases_servers, ' ')

    $all_releases_servers_array.each |String $releases_server| {
        unless $deployment_server == $releases_server {
            rsync::quickdatacopy { "srv-patches-${releases_server}":
                ensure      => present,
                auto_sync   => true,
                delete      => true,
                source_host => $deployment_server,
                dest_host   => $releases_server,
                module_path => '/srv/patches',
            }
        }
    }
}
