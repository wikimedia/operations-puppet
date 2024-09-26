# = class: profile::mediawiki::scap_proxy
#
# Sets up an rsync proxy for scap, if the server is set up to be one
#
class profile::mediawiki::scap_proxy(
    Array[Stdlib::Host] $scap_proxies = lookup('scap::dsh::scap_proxies', {'default_value' => []}),
) {
    include ::network::constants

    # Yes, this is an antipattern. But in the end it's the easiest way
    # to organize code and data. Deal with it :P
    if member($scap_proxies, $::fqdn) {
        class { '::rsync::server': }

        rsync::server::module { 'common':
            path        => '/srv/mediawiki',
            read_only   => 'yes',
            hosts_allow => $::network::constants::mw_appserver_networks;
        }

        firewall::service { 'rsyncd_scap_proxy':
            proto    => 'tcp',
            port     => 873,
            src_sets => ['MW_APPSERVER_NETWORKS']
        }
    }

}
