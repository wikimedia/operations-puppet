# SPDX-License-Identifier: Apache-2.0
# @summary profile to configure bgpalerter
# @param asn The ASN to monitor
# @param group notification group
# @param user used to run service
# @param upstreams list of valid upstreams
# @param downstreams list of valid downstreams
# @param reports a list of bgpalert reports to configure
# @param monitors a list of bgpalert monitors to configure
# @param http_proxy optional http proxy server to use
class profile::bgpalerter(
    Integer[1]                 $asn         = lookup('profile::bgpalerter::asn'),
    String[1]                  $user        = lookup('profile::bgpalerter::user'),
    String[1]                  $group       = lookup('profile::bgpalerter::group'),
    Bgpalerter::Rpki           $rpki        = lookup('profile::bgpalerter::rpki'),
    Array[Integer[1]]          $upstreams   = lookup('profile::bgpalerter::upstreams'),
    Array[Integer[1]]          $downstreams = lookup('profile::bgpalerter::downstreams'),
    Array[Bgpalerter::Report]  $reports     = lookup('profile::bgpalerter::reports'),
    Array[Bgpalerter::Monitor] $monitors    = lookup('profile::bgpalerter::monitors'),
    Optional[Stdlib::HTTPUrl]  $http_proxy  = lookup('profile::bgpalerter::http_proxy'),
) {
    include network::constants
    # Curently we use the same config for all prefixes
    $prefix_config = {
        'description'         => 'No description provided',
        'asn'                 => [$asn],
        'ignoreMorespecifics' => false,
        'ignore'              => false,
        'group'               => $group,
    }
    $all_external_networks = concat($network::constants::external_networks,
                                    $network::constants::customers_networks)
    $prefixes = Hash($all_external_networks.map |$net| {
        [$net, $prefix_config]
    })
    $prefixes_options = {
        'monitorASns' => {
            String($asn) => {
                'group'       => $group,
                'upstreams'   => $upstreams,
                'downstreams' => $downstreams,
            },
        },
    }
    systemd::sysuser { $user:
        id          => '917:917',         # https://wikitech.wikimedia.org/wiki/UID
        description => 'Bgpalerter User',
        before      => Class['bgpalerter'],
    }
    class { 'bgpalerter':
        rpki             => $rpki,
        reports          => $reports,
        monitors         => $monitors,
        httpProxy        => $http_proxy,
        prefixes         => $prefixes,
        prefixes_options => $prefixes_options,
        manage_user      => false,
        user             => $user,
    }
}
