class profile::dumps::distribution::mirrors::rsync_config(
    $rsync_mirrors = hiera('profile::dumps::distribution::datasets::mirrors'),
    $rsyncer_settings = hiera('profile::dumps::distribution::rsync_config'),
    $xmldumpsdir = hiera('profile::dumps::distribution::xmldumpspublicdir'),
    $miscdatasetsdir = hiera('profile::dumps::distribution::miscdumpsdir'),
) {
    $active_mirrors = $rsync_clients.filter |$item| { item['active'] == 'yes' }
    $ipv4_mirrors = $active_mirrors.reduce |$item| { item['ipv4'] }
    $ipv6_mirrors = $active_mirrors.reduce |$item| { item['ipv6'] }
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
