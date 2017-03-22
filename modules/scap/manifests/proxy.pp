# = class: scap::proxy
#
# Sets up an rsync proxy for scap
class scap::proxy {
    include rsync::server
    include network::constants

    rsync::server::module { 'common':
        path        => '/srv/mediawiki',
        read_only   => 'yes',
        hosts_allow => $::network::constants::mw_appserver_networks;
    }

    class { '::scap::vhost':
        deployable_networks => $::network::constants::deployable_networks,
    }
}
