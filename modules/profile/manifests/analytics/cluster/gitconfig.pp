# == Class profile::analytic::cluster::gitconfig
#
# Set system level git config properties to be picked up
# by all the git::clones done whithin the Analytics
# Cluster/VLAN.
#
class profile::analytics::cluster::gitconfig {
    class { 'git::systemconfig':
        settings => {
            # https://wikitech.wikimedia.org/wiki/HTTP_proxy
            'http'  => {
                'proxy' => "http://webproxy.${::site}.wmnet:8080"
            },
            'https' => {
                'proxy' => "http://webproxy.${::site}.wmnet:8080"
            },
        },
    }
}