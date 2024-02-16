# SPDX-License-Identifier: Apache-2.0
# == Class profile::analytic::cluster::gitconfig
#
# Set system level git config properties to be picked up
# by all the git::clones done whithin the Analytics
# Cluster/VLAN.
#
class profile::analytics::cluster::gitconfig (
    Optional[Stdlib::HTTPUrl] $http_proxy = lookup('http_proxy'),
) {

    # Specific global git config for all the Analytics VLAN
    # to force every user to use the Production Webproxy.
    # This is useful to avoid HTTP/HTTPS calls ending up
    # being blocked by the VLAN's firewall rules, avoiding
    # all the users to set up their own settings.
    # Not needed in labs.
    if $http_proxy {
        git::systemconfig { 'setup_http_proxy':
            settings => {
                # https://wikitech.wikimedia.org/wiki/HTTP_proxy
                'http'  => {
                    'proxy' => $http_proxy,
                },
                'https' => {
                    'proxy' => $http_proxy,
                },
            },
        }
    }
}
