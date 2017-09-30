class dumps::rsync::pagecounts_ez(
    $hosts_allow = undef,
) {
    include ::dumps::rsync::common

    file { '/etc/rsyncd.d/30-rsync-pagecounts_ez.conf':
        ensure  => 'present',
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => templates('dumps/rsync/rsyncd.conf.pagecounts_ez.erb'),
        notify  => Exec['update-rsyncd.conf'],
    }
}
