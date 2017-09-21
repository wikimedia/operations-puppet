class dumps::rsync::phab_dump {
    include ::dumps::rsync::common
    file { '/etc/rsyncd.d/40-rsync-phab_dump.conf':
        ensure => 'present',
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dumps/rsync/rsyncd.conf.phab_dump',
        notify => Exec['update-rsyncd.conf'],
    }
}
