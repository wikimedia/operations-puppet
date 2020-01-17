class profile::dumps::distribution::datasets::fetcher(
    $xmldumpsdir = lookup('profile::dumps::distribution::xmldumpspublicdir'),
    $miscdatasetsdir = lookup('profile::dumps::distribution::miscdumpsdir'),
    $rsyncer_settings = lookup('profile::dumps::distribution::rsync_config'),
    $use_kerberos = lookup('profile::dumps::distribution::datasets::fetcher::use_kerberos', { 'default_value' => false }),
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
        src_hdfs        => '/wmf/data/archive',
        miscdatasetsdir => $miscdatasetsdir,
        user            => $user,
        use_kerberos    => $use_kerberos,
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
