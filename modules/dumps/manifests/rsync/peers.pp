class dumps::rsync::peers(
    $hosts_allow = undef,
) {
    include ::dumps::rsync::common
    file { '/etc/rsyncd.d/10-rsync-datasets_to_peers.conf':
        ensure  => 'present',
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('dumps/rsync/rsyncd.conf.datasets_to_peers.erb'),
        notify  => Exec['update-rsyncd.conf'],
    }
}
