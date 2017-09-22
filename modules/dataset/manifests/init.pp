class dataset(
    # args:
    #    $nfs: true to share data with snapshot hosts via nfs
    #    $rsync: 'peer'   for rsync of data between internal peers
    #                     (wmf servers)
    #            'labs'   for rsync of some dumps to labs public fileshare
    $nfs     = true,
    $rsync   = {},
    $uploads = {},
    $grabs   = {}
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

    $rsync_peers_enable = has_key($rsync,'peers')
    class { '::dataset::cron::rsync::peers': enable => $rsync_peers_enable }

    $rsync_labs_enable = has_key($rsync,'labs')
    class { '::dataset::cron::rsync::labs': enable => $rsync_labs_enable }

}
