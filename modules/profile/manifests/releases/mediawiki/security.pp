# server hosting MediaWiki releases
# https://releases.wikimedia.org/mediawiki/
class profile::releases::mediawiki::security (
    Stdlib::Fqdn $deployment_server = lookup('deployment_server'),
    Stdlib::Fqdn $releases_server = lookup('releases_server'),
){

    rsync::quickdatacopy { 'srv-patches':
        ensure      => present,
        auto_sync   => true,
        source_host => $deployment_server,
        dest_host   => $releases_server,
        module_path => '/srv/patches',
    }
}
