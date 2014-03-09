class dataset::rsync::default(
    $rsync_enable      = 'true', # this is a string used in a template
    $public            = true,
    $rsync_opts        = '--bwlimit=50000',
    $rsync_config_file = undef
    ) {
    if $public == true {
        $rsync_nice = '10'
        $rsync_ionice = '-c3'
    }
    else {
        $rsync_nice = undef
        $rsync_ionice = undef
    }

    file { '/etc/default/rsync':
        ensure   => 'present',
        mode     => '0444',
        owner    => 'root',
        group    => 'root',
        content  => template('dataset/rsync.default.erb'),
    }
}
