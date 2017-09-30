class dumps::rsync::media(
    $hosts_allow = undef,
) {
    include ::dumps::rsync::common

    file { '/etc/rsyncd.d/30-rsync-media.conf':
        ensure  => 'present',
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => templates('dumps/rsync/rsyncd.conf.media'),
        notify  => Exec['update-rsyncd.conf'],
    }
}
