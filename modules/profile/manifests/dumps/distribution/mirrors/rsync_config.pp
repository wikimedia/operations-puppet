class profile::dumps::distribution::mirrors::rsync_config(
    $rsync_mirrors = hiera('profile::dumps::distribution::datasets::mirrors'),
    $rsyncer_settings = hiera('profile::dumps::distribution::rsync_config'),
    $xmldumpsdir = hiera('profile::dumps::distribution::xmldumpspublicdir'),
    $miscdatasetsdir = hiera('profile::dumps::distribution::miscdumpsdir'),
) {
    # FIXME this is python shoved in here because dunno how to do list compr in puppet
    $ipv4_mirrors = [ item['ipv4'] for item in $rsync_clients if item['active'] == 'yes'] ]
    $ipv6_mirrors = [ item['ipv6'] for item in $rsync_clients if item['active'] == 'yes'] ]
    $hosts_allow = join(concat($ipv4_mirrors, $ipv6_mirrors, ' ')

    file { '/etc/rsyncd.d/20-rsync-dumps_to_public.conf':
        ensure  => 'present',
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('profile/dumps/distribution/mirrors/rsyncd.conf.dumps_to_public.erb'),
        notify  => Exec['update-rsyncd.conf'],
    }
}
