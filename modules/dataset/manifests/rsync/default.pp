class dataset::rsync::default(
    $rsync_enable      = true,
    $public            = true,
    $rsync_opts        = '--bwlimit=50000',
    $rsync_config_file = undef
    ) {
    if $public == true {
        $rsync_nice = undef
        $rsync_ionice = undef
    }
    else {
        $rsync_nice = '10'
        $rsync_ionice = '-c3'
    }

    file { '/etc/default/rsync':
        ensure  => 'present',
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('dataset/rsync.default.erb'),
    }
}
