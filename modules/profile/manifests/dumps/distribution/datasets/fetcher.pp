class profile::dumps::distribution::datasets::fetcher(
    $xmldumpsdir = hiera('profile::dumps::distribution::xmldumpspublicdir'),
    $miscdatasetsdir = hiera('profile::dumps::distribution::miscdumpsdir'),
    $rsyncer_settings = hiera('profile::dumps::distribution::rsync_config'),
) {

    $user = $rsyncer_settings['dumps_user']
    $group = $rsyncer_settings['dumps_group']

    class {'dumps::web::fetches::kiwix':
        user            => $user,
        group           => $group,
        xmldumpsdir     => $xmldumpsdir,
        miscdatasetsdir => $miscdatasetsdir,
    }

    class {'dumps::web::fetches::stats':
        src             => 'stat1007.eqiad.wmnet::hdfs-archive',
        miscdatasetsdir => $miscdatasetsdir,
        user            => $user,
    }

    class {'dumps::web::fetches::stat_dumps':
        src             => 'stat1007.eqiad.wmnet::srv/dumps',
        miscdatasetsdir => $miscdatasetsdir,
        user            => $user,
    }

    class {'dumps::web::fetches::wikitech_dumps':
        url             => 'https://wikitech.wikimedia.org/dumps/',
        miscdatasetsdir => $miscdatasetsdir,
    }

    class {'dumps::web::fetches::phab':
        src             => 'phab1001.eqiad.wmnet::srvdumps',
        miscdatasetsdir => $miscdatasetsdir,
        user            => root,
    }
}
