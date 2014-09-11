class role::url-downloader {
    system::role { 'url-downloader':
        description => 'Upload-by-URL proxy'
    }

    # TODO: Need to parameterize this to account for:
    # Interface::Ip['url-downloader']],
    include ::url-dowloader


    # pin package to the default, Ubuntu version, instead of our own
    if $::lsbdistid == 'Ubuntu' and versioncmp($::lsbdistrelease, '12.04') >= 0 {
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
        before   => Class['url-downloader'],
    }

    # Firewall
    ferm::service {'url-downloader':
        proto => 'tcp',
        port  => '8080',
    }

    # Monitoring
    monitor_service { 'url-dowloader':
        description   => 'url-dowloader',
        check_command => 'check_tcp!8080',
    }
}
