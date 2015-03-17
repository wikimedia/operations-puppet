# = class: scap::master
#
# Sets up a scap master (currently tin). 
class scap::master(
    $common_path = '/srv/mediawiki',
    $common_source_path = '/srv/mediawiki-staging',
    $rsync_host = 'tin.eqiad.wmnet',
    $statsd_host = 'statsd.eqiad.wmnet',
    $statsd_port = 8125,
    $deployment_group = wikidev,
) {
    include scap::scripts
    include rsync::server
    include network::constants
    include dsh

    git::clone { 'operations/mediawiki-config':
        directory => $common_source_path,
        ensure    => present,
        group     => $deployment_group,
        mode      => '0774'
    }

    rsync::server::module { 'common':
        path        => $common_source_path,
        read_only   => 'yes',
        hosts_allow => $::network::constants::mw_appserver_networks;
    }
}
