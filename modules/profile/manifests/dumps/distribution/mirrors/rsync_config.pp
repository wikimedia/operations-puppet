# SPDX-License-Identifier: Apache-2.0
class profile::dumps::distribution::mirrors::rsync_config(
    Array $rsync_mirrors = lookup('profile::dumps::distribution::mirrors'),
    Hash $rsyncer_settings = lookup('profile::dumps::distribution::rsync_config'),
    Stdlib::Unixpath $xmldumpsdir = lookup('profile::dumps::distribution::xmldumpspublicdir'),
    Stdlib::Unixpath $miscdatasetsdir = lookup('profile::dumps::distribution::miscdumpsdir'),
) {
    $hosts_allow = $rsync_mirrors
        .filter |$item| { $item['active'] == 'yes' }
        .map |$item| { $item['hosts'] }
        .flatten()
        .wmflib::hosts2ips()
        .join(' ')

    file { '/etc/rsyncd.d/20-rsync-dumps_to_public.conf':
        ensure  => 'present',
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('profile/dumps/distribution/mirrors/rsyncd.conf.dumps_to_public.erb'),
        notify  => Exec['update-rsyncd.conf'],
    }
}
