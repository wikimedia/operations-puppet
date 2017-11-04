class dumps::rsync::default(
    $rsync_opts = undef,
) {
    file { '/etc/default/rsync':
        ensure  => 'present',
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('dumps/rsync/rsync.default.erb'),
    }
}
