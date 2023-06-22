# SPDX-License-Identifier: Apache-2.0
# Class: vrts::web
#
# This class configures the apache part of the WMF VRTS installation
#
# Parameters:

# Actions:
#       Install the necessary apache modules, configure SSL
#
# Requires:
#
# Sample Usage:
#   include vrts::web
#
class vrts::web {

    # We override the default mpm_prefork to set the apache setting for
    # MaxConnectionsPerChild. The chosen number is experimentally derived from
    # an VRTS suggested apache configuration example along with some experiments
    # Otherwise, VRTS memory leaks through the roof causing OOM to show up
    # We use the declarative form of the class instead of the inclusion to
    # explicitly show that we use the prefork mpm
    class { '::httpd::mpm':
        mpm    => 'prefork',
        source => 'puppet:///modules/vrts/mpm_prefork.conf',
    }

    httpd::site { 'ticket.wikimedia.org':
        content => template('vrts/ticket.wikimedia.org.erb'),
    }

    rsyslog::input::file { 'vrts-apache2-error':
        path => '/var/log/apache2/*error*.log',
    }

    rsyslog::input::file { 'vrts-apache2-access':
        path => '/var/log/apache2/*access*.log',
    }
}
