# SPDX-License-Identifier: Apache-2.0
class profile::dumps::distribution::mirrors::rsync_config(
    Array $rsync_mirrors = lookup('profile::dumps::distribution::mirrors'),
    Hash $rsyncer_settings = lookup('profile::dumps::distribution::rsync_config'),
    Stdlib::Unixpath $xmldumpsdir = lookup('profile::dumps::distribution::xmldumpspublicdir'),
    Stdlib::Unixpath $miscdatasetsdir = lookup('profile::dumps::distribution::miscdumpsdir'),
) {
    $active_mirrors = $rsync_mirrors.filter |$item| { $item['active'] == 'yes' }
    $ipv4_mirrors = $active_mirrors.reduce([]) |$mirrorlist, $item| { $mirrorlist + $item['ipv4'] }
    $ipv6_mirrors = $active_mirrors.reduce([]) |$mirrorlist, $item| { $mirrorlist + $item['ipv6'] }

    $hosts_allow = join(flatten($ipv4_mirrors + $ipv6_mirrors), ' ')

    file { '/etc/rsyncd.d/20-rsync-dumps_to_public.conf':
        ensure  => 'present',
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('profile/dumps/distribution/mirrors/rsyncd.conf.dumps_to_public.erb'),
        notify  => Exec['update-rsyncd.conf'],
    }
}
