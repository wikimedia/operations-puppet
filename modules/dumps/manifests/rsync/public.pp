class dumps::rsync::public {
    include ::dumps::rsync::common
    file { '/etc/rsyncd.d/20-rsync-dumps_to_public.conf':
        ensure => 'present',
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dumps/rsync/rsyncd.conf.dumps_to_public',
        notify => Exec['update-rsyncd.conf'],
    }
}
