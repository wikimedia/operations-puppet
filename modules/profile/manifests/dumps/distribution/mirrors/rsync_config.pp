# SPDX-License-Identifier: Apache-2.0
class profile::dumps::distribution::mirrors::rsync_config(
    Array $rsync_mirrors = lookup('profile::dumps::distribution::mirrors'),
    Hash $rsyncer_settings = lookup('profile::dumps::distribution::rsync_config'),
    Stdlib::Unixpath $xmldumpsdir = lookup('profile::dumps::distribution::xmldumpspublicdir'),
    Stdlib::Unixpath $miscdatasetsdir = lookup('profile::dumps::distribution::miscdumpsdir'),
) {
    $mirror_hosts = $rsync_mirrors
        .filter |$item| { $item['active'] == 'yes' }
        .map |$item| { $item['hosts'] }
        .flatten()
        .wmflib::hosts2ips()

    $hosts_allow = $mirror_hosts.join(' ')

    file { '/etc/rsyncd.d/20-rsync-dumps_to_public.conf':
        ensure  => 'present',
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('profile/dumps/distribution/mirrors/rsyncd.conf.dumps_to_public.erb'),
        notify  => Exec['update-rsyncd.conf'],
    }

    firewall::service { 'dumps_rsyncd_public':
        port   => 873,
        proto  => 'tcp',
        srange => $mirror_hosts,
        qos    => 'low',
    }
}
