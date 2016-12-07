class role::installserver {
    system::role { 'role::install_server':
        description => 'WMF Install server. APT repo, Forward Caching, TFTP, \
                        DHCP and Web server',
    }

    include standard
    include role::backup::host
    include install_server::preseed_server

    # Backup
    $sets = [ 'srv-autoinstall',
            ]
    backup::set { $sets : }

}
