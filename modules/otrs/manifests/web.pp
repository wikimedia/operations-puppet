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
    # MaxConnectionsPerChild. The chosen number is experimentally derived from
    # an OTRS suggested apache configuration example along with some experiments
    # Otherwise, OTRS memory leaks through the roof causing OOM to show up
    # We use the declarative form of the class instead of the inclusion to
    # explicitly show that we use the prefork mpm
    class { '::apache::mpm':
        mpm    => 'prefork',
        source => 'puppet:///modules/otrs/mpm_prefork.conf',
    }

    # this site's misc-lb caching proxies hostnames
    $cache_misc_nodes = hiera('cache::misc::nodes')
    $trusted_proxies = $cache_misc_nodes[$::site]

    apache::site { 'ticket.wikimedia.org':
        content => template('otrs/ticket.wikimedia.org.erb'),
    }
}
