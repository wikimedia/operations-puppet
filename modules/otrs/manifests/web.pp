# Class: otrs::web
#
# This class configures the apache part of the otrs WMF installation
#
# Parameters:

# Actions:
#       Install the necessary apache modules, configure SSL
#
# Requires:
#
# Sample Usage:
#   include otrs::web
#
class otrs::web {
    include ::apache::mod::perl
    include ::apache::mod::remoteip
    include ::apache::mod::rewrite
    include ::apache::mod::headers

    # We override the default mpm_prefork to set the apache setting for
    # MaxConnectionsPerChild to 4000. 4000 is an arbitrary number derived from
    # an OTRS suggested apache configuration example and some experimentation
    # Otherwise, OTRS memory leaks through the roof causing OOM to show up
    apache::conf { 'mpm_prefork':
        ensure => present,
        source => 'puppet:///modules/otrs/mpm_prefork.conf',
    }

    # this site's misc-lb caching proxies hostnames
    $cache_misc_nodes = hiera('cache::misc::nodes')
    $trusted_proxies = $cache_misc_nodes[$::site]

    apache::site { 'ticket.wikimedia.org':
        content => template('otrs/ticket.wikimedia.org.erb'),
    }
}
