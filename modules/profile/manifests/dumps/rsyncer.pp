class profile::dumps::rsyncer(
    $rsync_clients = hiera('dumps_web_rsync_server_clients'),
    $rsyncer_settings = hiera('profile::dumps::rsyncer'),
) {
    $user = $rsyncer_settings['dumps_user']
    $group = $rsyncer_settings['dumps_group']
    $deploygroup = $rsyncer_settings['dumps_deploygroup']
    $mntpoint = $rsyncer_settings['dumps_mntpoint']

    $stats_hosts = 'stat1005.eqiad.wmnet stat1006.eqiad.wmnet'
    $peer_hosts = 'dataset1001.wikimedia.org ms1001.wikimedia.org dumpsdata1001.eqiad.wmnet dumpsdata1002.eqiad.wmnet labstore1006.wikimedia.org labstore1007.wikimedia.org'
    $phab_hosts = 'phab1001.eqiad.wmnet'
    $mwlog_hosts = 'mwlog1001.eqiad.wmnet 2620:0:861:103:1618:77ff:fe33:4ac0 mwlog2001.codfw.wmnet 2620:0:860:103:1618:77ff:fe4e:3159'

    $hosts_allow = join(concat($rsync_clients['ipv4']['external'], $rsync_clients['ipv6']['external']), ' ')

    $xmldumpsdir = "${mntpoint}/xmldatadumps"
    $publicdir = "${xmldumpsdir}/public"
    $otherdir = "${publicdir}/other"

    class {'::dumps::rsync::common':
        user  => $user,
        group => $group,
    }

    class {'::dumps::rsync::default':}

    class {'::dumps::rsync::media':
        hosts_allow => $stats_hosts,
        user        => $user,
        deploygroup => $deploygroup,
        otherdir    => $otherdir,
    }

    class {'::vm::higher_min_free_kbytes':}

    class {'::dumps::rsync::pagecounts_ez':
        hosts_allow => $stats_hosts,
        user        => $user,
        deploygroup => $deploygroup,
        otherdir    => $otherdir,
    }

    class {'::dumps::rsync::peers':
        hosts_allow => $peer_hosts,
        datapath    => $mntpoint,
    }

    class {'::dumps::rsync::phab_dump':
        hosts_allow => $phab_hosts,
        otherdir    => $otherdir,
    }

    class {'::dumps::rsync::public':
        hosts_allow => $hosts_allow,
        publicdir   => $publicdir,
        otherdir    => $otherdir,
    }

    class {'::dumps::rsync::slowparse_logs':
        hosts_allow => $mwlog_hosts,
        user        => $user,
        group       => $group,
        otherdir    => $otherdir,
    }

    class {'::dumps::web::dumplists':
        xmldumpsdir => $xmldumpsdir,
        user        => $user,
    }
}
