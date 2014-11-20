# === Class deployment::scap_proxy
#
# Sets up a scap proxy server.
class deployment::scap_proxy {
    include rsync::server
    include network::constants

    rsync::server::module { 'common':
        path        => '/srv/mediawiki',
        read_only   => 'true',
        hosts_allow => $::network::constants::mw_appserver_networks;
    }
}
