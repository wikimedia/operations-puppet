# = class: profile::mediawiki::scap_proxy
#
# Sets up an rsync proxy for scap, it the server is set up to be one
#
class profile::mediawiki::scap_proxy(
    $scap_proxies = hiera('scap::dsh::scap_proxies',[])
) {
    include ::network::constants
    if member($scap_proxies, $::fqdn) {
        class { '::rsync::server': }

        rsync::server::module { 'common':
            path        => '/srv/mediawiki',
            read_only   => 'yes',
            hosts_allow => $::network::constants::mw_appserver_networks;
        }

        ferm::service { 'rsyncd_scap_proxy':
            proto  => 'tcp',
            port   => '873',
            srange => '$MW_APPSERVER_NETWORKS',
        }
    }

}
