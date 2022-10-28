# SPDX-License-Identifier: Apache-2.0
class profile::dumps::distribution::datasets::rsync_config(
    $rsyncer_settings = lookup('profile::dumps::distribution::rsync_config'),
    $stats_hosts = lookup('profile::dumps::stats_hosts'),
    $peer_hosts = lookup('profile::dumps::peer_hosts'),
    $phab_hosts = lookup('profile::dumps::phab_hosts'),
    $xmldumpsdir = lookup('profile::dumps::distribution::xmldumpspublicdir'),
    $miscdatasetsdir = lookup('profile::dumps::distribution::miscdumpsdir'),
) {

    $user = $rsyncer_settings['dumps_user']
    $group = $rsyncer_settings['dumps_group']
    $deploygroup = $rsyncer_settings['dumps_deploygroup']
    $mntpoint = $rsyncer_settings['dumps_mntpoint']

    file { '/etc/rsyncd.d/30-rsync-media.conf':
        ensure  => 'present',
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('profile/dumps/distribution/datasets/rsyncd.conf.media.erb'),
        notify  => Exec['update-rsyncd.conf'],
    }

    file { '/etc/rsyncd.d/30-rsync-pagecounts_ez.conf':
        ensure  => 'present',
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('profile/dumps/distribution/datasets/rsyncd.conf.pagecounts_ez.erb'),
        notify  => Exec['update-rsyncd.conf'],
    }

    file { '/etc/rsyncd.d/40-rsync-phab_dump.conf':
        ensure  => 'present',
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('profile/dumps/distribution/datasets/rsyncd.conf.phab_dump.erb'),
        notify  => Exec['update-rsyncd.conf'],
    }

    class {'::dumps::rsync::peers':
        hosts_allow => $peer_hosts,
        datapath    => $mntpoint,
    }

    class {'::dumps::web::dumplists':
        xmldumpsdir => $xmldumpsdir,
        user        => $user,
    }
}
