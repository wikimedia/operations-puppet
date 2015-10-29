# = class: scap::master
#
# Sets up a scap master (currently tin)
class scap::master(
    $common_path        = '/srv/mediawiki',
    $common_source_path = '/srv/mediawiki-staging',
    $rsync_host         = 'tin.eqiad.wmnet',
    $statsd_host        = 'statsd.eqiad.wmnet',
    $statsd_port        = 8125,
    $deployment_group   = 'wikidev',
) {
    include scap::scripts
    include scap::dsh
    include rsync::server
    include network::constants
    include mediawiki::scap

    package { 'dsh':
        ensure => present,
    }

    git::clone { 'operations/mediawiki-config':
        directory => $common_source_path,
        ensure    => present,
        owner     => 'mwdeploy',
        group     => $deployment_group,
        shared    => true,
        before    => Exec['fetch_mediawiki'],
    }

    rsync::server::module { 'common':
        path        => $common_source_path,
        read_only   => 'yes',
        hosts_allow => $::network::constants::mw_appserver_networks;
    }

    class { 'scap::l10nupdate':
        deployment_group => $deployment_group,
    }
}
