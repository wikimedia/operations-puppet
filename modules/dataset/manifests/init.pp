class dataset(
    # args:
    #    $nfs: true to share data with snapshot hosts via nfs
    $nfs     = true,
    ) {

    include ::dataset::common
    require ::dataset::user

    if ($nfs) {
        $nfs_enable = true
    }
    else {
        $nfs_enable = false
    }
    class { '::dataset::nfs': enable => $nfs_enable }
}
