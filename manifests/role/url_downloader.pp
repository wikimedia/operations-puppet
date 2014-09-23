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
#       Definition Apt::pin
#       Module url_downloader
#       ferm
#       nagios definitions for wmf
#
# Sample Usage:
#       node /test.wikimedia.org/ {
#           $url_downlader_ip = '10.10.10.10' # A public IP really
#           include role::url_downloader
#       }
class role::url_downloader {
    system::role { 'url_downloader':
        description => 'Upload-by-URL proxy'
    }

    class { '::url_downloader':
        service_ip => $url_downloader_ip
    }

    # pin package to the default, Ubuntu version, instead of our own
    if ubuntu_version('>= 12.04') {
        $pinned_packages = [
                            'squid3',
                            'squid-common3',
                            'squid-langpack',
                        ]
        $before_package = 'squid3'
    } else {
        $pinned_packages = [
                            'squid',
                            'squid-common',
                            'squid-langpack',
                        ]
        $before_package = 'squid'
    }

    apt::pin { $pinned_packages:
        pin      => 'release o=Ubuntu',
        priority => '1001',
        before   => Class['::url_downloader'],
    }

    # Firewall
    ferm::service { 'url_downloader':
        proto => 'tcp',
        port  => '8080',
    }

    # Monitoring
    monitor_service { 'url_downloader':
        description   => 'url_downloader',
        check_command => 'check_tcp_ip!url-downloader.wikimedia.org!8080',
    }
}
