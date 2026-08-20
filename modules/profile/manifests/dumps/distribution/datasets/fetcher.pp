# SPDX-License-Identifier: Apache-2.0
class profile::dumps::distribution::datasets::fetcher(
    Stdlib::Unixpath $xmldumpsdir = lookup('profile::dumps::distribution::xmldumpspublicdir'),
    Stdlib::Unixpath $miscdatasetsdir = lookup('profile::dumps::distribution::miscdumpsdir'),
    Hash $rsyncer_settings = lookup('profile::dumps::distribution::rsync_config'),
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
        src_hdfs_archive => '/wmf/data/archive',
        src_hdfs_exports => '/wmf/data/exports',
        miscdatasetsdir  => $miscdatasetsdir,
        user             => $user,
    }

    # Cleanup HDFS FUSE bits, the modules above use hdfs-rsync (from
    # the hdfs_tools Puppet module) instead
    package { 'hadoop-hdfs-fuse':
        ensure => absent,
    }
    mount { 'hdfs-fuse':
        ensure => absent,
        name   => '/mnt/hdfs',
    }
}
