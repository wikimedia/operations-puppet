# SPDX-License-Identifier: Apache-2.0
class profile::dumps::distribution::datasets::rsync_config(
    Hash $rsyncer_settings = lookup('profile::dumps::distribution::rsync_config'),
    Array[Stdlib::Host, 1] $phab_hosts = lookup('profile::dumps::phab_hosts'),
    Stdlib::Unixpath $xmldumpsdir = lookup('profile::dumps::distribution::xmldumpspublicdir'),
    Stdlib::Unixpath $miscdatasetsdir = lookup('profile::dumps::distribution::miscdumpsdir'),
) {
    $phab_host_ips = $phab_hosts.wmflib::hosts2ips()

    $user = $rsyncer_settings['dumps_user']
    $group = $rsyncer_settings['dumps_group']
    $deploygroup = $rsyncer_settings['dumps_deploygroup']
    $mntpoint = $rsyncer_settings['dumps_mntpoint']

    dumps::rsync::fragment { 'phab_dump':
        content => template('profile/dumps/distribution/datasets/rsyncd.conf.phab_dump.erb'),
    }

    firewall::service { 'dumps_rsyncd_phabricator':
        port   => 873,
        proto  => 'tcp',
        srange => $phab_host_ips,
    }

    class {'::dumps::web::dumplists':
        xmldumpsdir => $xmldumpsdir,
        user        => $user,
    }
}
