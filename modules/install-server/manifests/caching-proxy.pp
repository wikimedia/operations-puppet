# Class: install-server::caching-proxy
#
# This class installs squid and configures it
#
# Parameters:
#
# Actions:
#       Install squid and configure it as a caching forward proxy
#
# Requires:
#
# Sample Usage:
#   include install-server::caching-proxy

class install-server::caching-proxy {
    class { 'squid3':
        config_source => 'puppet:///modules/install-server/squid3-apt-proxy.conf',
    }
}
