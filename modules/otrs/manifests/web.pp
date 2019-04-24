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

    # We override the default mpm_prefork to set the apache setting for
    # MaxConnectionsPerChild. The chosen number is experimentally derived from
    # an OTRS suggested apache configuration example along with some experiments
    # Otherwise, OTRS memory leaks through the roof causing OOM to show up
    # We use the declarative form of the class instead of the inclusion to
    # explicitly show that we use the prefork mpm
    class { '::httpd::mpm':
        mpm    => 'prefork',
        source => 'puppet:///modules/otrs/mpm_prefork.conf',
    }

    # this site's cache_text proxies hostnames
    $cache_text_nodes = hiera('cache::nodes')['text']
    $trusted_proxies = $cache_text_nodes[$::site]

    httpd::site { 'ticket.wikimedia.org':
        content => template('otrs/ticket.wikimedia.org.erb'),
    }
}
