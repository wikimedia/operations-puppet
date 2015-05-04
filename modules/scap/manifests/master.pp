# = class: scap::master
#
# Sets up a scap master (currently tin)
class scap::master(
    $common_path        = undef,
    $common_source_path = undef,
    $rsync_host         = undef,
    $statsd_host        = undef,
    $statsd_port        = undef,
    $deployment_group   = undef,
) {
    include scap::scripts
    include rsync::server
    include network::constants
    include dsh

    git::clone { 'operations/mediawiki-config':
        directory => $common_source_path,
        ensure    => present,
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
