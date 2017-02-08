# sets up preseeding dir and config on an install server
class role::installserver::preseed {

    include ::standard
    include ::role::backup::host
    include install_server::preseed_server

    # Backup
    $sets = [ 'srv-autoinstall',
            ]
    backup::set { $sets : }

}
