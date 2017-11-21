class profile::dumps::web::statusfiles_sync(
    $rsyncer_peer_settings = hiera('profile::dumps::rsyncer_peer'),
) {
    $mntpoint = $rsyncer_peer_settings['dumps_mntpoint']
    class {'::dumps::web::statusfiles':
        xmldumpsdir => "${mntpoint}/xmldatadumps/public",
    }
}
