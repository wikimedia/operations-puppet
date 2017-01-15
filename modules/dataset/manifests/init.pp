class dataset(
    # args:
    #    $nfs: true to share data with snapshot hosts via nfs
    #    $rsync: 'public' for rsync of data to the public
    #            'peer'   for rsync of data between internal peers
    #                     (wmf servers)
    #            'labs'   for rsync of some dumps to labs public fileshare
    #    $uploads: 'pagecounts_ez' to allow the corresponding rsync
    #              to those directories from the appropriate hosts
    #              'phab' for rsync of phabricator dump from hosts that have it
    #    $grabs: 'kiwix' to copy kiwix (offline wiki) tarballs from upstream
    #            to local filesystem

    $nfs     = true,
    $rsync   = {},
    $uploads = {},
    $grabs   = {}
    ) {

    include ::dataset::common
    require ::dataset::user

    $rsync_public_enable = has_key($rsync,'public')
    class { '::dataset::rsync::public': enable => $rsync_public_enable }
    class { '::dataset::rsync::default': public => $rsync_public_enable }

    if ($nfs) {
        $nfs_enable = true
    }
    else {
        $nfs_enable = false
    }
    class { '::dataset::nfs': enable => $nfs_enable }

    $rsync_peers_enable = has_key($rsync,'peers')
    class { '::dataset::rsync::peers': enable => $rsync_peers_enable }
    class { '::dataset::cron::rsync::peers': enable => $rsync_peers_enable }

    $rsync_labs_enable = has_key($rsync,'labs')
    class { '::dataset::cron::rsync::labs': enable => $rsync_labs_enable }

    $uploads_pagecounts_ez_enable = has_key($uploads,'pagecounts_ez')
    class { '::dataset::rsync::pagecounts_ez':
        enable => $uploads_pagecounts_ez_enable }

    $uploads_phab_dump_enable = has_key($uploads,'phab')
    class { '::dataset::rsync::phab_dump':
        enable => $uploads_phab_dump_enable }

    $grabs_kiwix_enable = has_key($grabs,'kiwix')
    class { '::dataset::cron::kiwix': enable => $grabs_kiwix_enable }

    include ::dataset::html
}
