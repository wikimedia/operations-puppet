# Class: url_downloader
#
# This class installs squid as a forward proxy for fetching URLs
#
# Parameters:
#   $service_ip
#       The IP on which the proxy listens on and uses to fetch URLs
#
# Actions:
#       Install squid and configure it as a forward fetching proxy
#
# Requires:
#
# Sample Usage:
#       class { '::url_downloader':
#           service_ip  => '10.10.10.10' # Probably a public ip though
#       }
class url_downloader($service_ip) {
    class { 'squid3':
        config_content => template('url_downloader/squid.conf.erb'),
    }
}
