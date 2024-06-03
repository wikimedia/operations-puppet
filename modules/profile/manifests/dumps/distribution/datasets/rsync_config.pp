# SPDX-License-Identifier: Apache-2.0
class profile::dumps::distribution::datasets::rsync_config(
    Hash $rsyncer_settings = lookup('profile::dumps::distribution::rsync_config'),
    String $peer_hosts = lookup('profile::dumps::peer_hosts'),
    String $phab_hosts = lookup('profile::dumps::phab_hosts'),
    Stdlib::Unixpath $xmldumpsdir = lookup('profile::dumps::distribution::xmldumpspublicdir'),
    Stdlib::Unixpath $miscdatasetsdir = lookup('profile::dumps::distribution::miscdumpsdir'),
) {

    $user = $rsyncer_settings['dumps_user']
    $group = $rsyncer_settings['dumps_group']
    $deploygroup = $rsyncer_settings['dumps_deploygroup']
    $mntpoint = $rsyncer_settings['dumps_mntpoint']

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
