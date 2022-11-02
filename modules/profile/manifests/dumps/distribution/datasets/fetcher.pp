# SPDX-License-Identifier: Apache-2.0
class profile::dumps::distribution::datasets::fetcher(
    Stdlib::Unixpath $xmldumpsdir = lookup('profile::dumps::distribution::xmldumpspublicdir'),
    Stdlib::Unixpath $miscdatasetsdir = lookup('profile::dumps::distribution::miscdumpsdir'),
    Hash $rsyncer_settings = lookup('profile::dumps::distribution::rsync_config'),
    Stdlib::Host $stat_dump_host = lookup('profile::dumps::distribution::stat_dump_host'),
    Stdlib::Host $phab_dump_host = lookup('profile::dumps::distribution::phab_dump_host'),
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
    }

    class {'dumps::web::fetches::stat_dumps':
        src             => "${stat_dump_host}::srv/dumps",
        miscdatasetsdir => $miscdatasetsdir,
        user            => $user,
    }

    class {'dumps::web::fetches::wikitech_dumps':
        url             => 'https://wikitech.wikimedia.org/dumps/',
        miscdatasetsdir => $miscdatasetsdir,
    }

    class {'dumps::web::fetches::phab':
        src             => "${phab_dump_host}::srv-dumps",
        miscdatasetsdir => $miscdatasetsdir,
        user            => root,
    }
}
