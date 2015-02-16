# Class: role::url_downloader
#
# A role class for assigning the url_downloader role to a host. The host needs
# to have the $url_downloader_ip variable set at node level (or via hiera)
#
# Parameters:
#
# Actions:
#       Use the url_downloader module class to configure a squid service
#       Setup firewall rules
#       Setup monitoring rules
#       Pin our packages
#
# Requires:
#       Module url_downloader
#       ferm
#       nagios definitions for wmf
#
# Sample Usage:
#       node /test.wikimedia.org/ {
#           $url_downlader_ip = '10.10.10.10' # A public IP really
#           include role::url_downloader
#       }
class role::url_downloader($url_downloader_ip) {
    system::role { 'url_downloader':
        description => 'Upload-by-URL proxy'
    }

    class { 'squid3':
        config_content => template('url_downloader/squid.conf.erb'),
    }

    # Firewall
    ferm::service { 'url_downloader':
        proto => 'tcp',
        port  => '8080',
    }

    # Monitoring
    monitoring::service { 'url_downloader':
        description   => 'url_downloader',
        check_command => 'check_tcp_ip!url-downloader.wikimedia.org!8080',
    }
}
