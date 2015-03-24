define labs_storage::snapshots(
    $filesystem,
    $hour          = '*',
    $minute        = '5',
)
{
    if ! $filesystem {
        fail('Parameter $filesystem must be specified')
    }

    cron { "snapshot-$filesystem":
        command => "/usr/local/sbin/storage-snapshot '$filesystem'",
        user    => 'root',
        hour    => $hour,
        minute  => $minute,
        require => File['/usr/local/sbin/storage-snapshot'],
    }

    # This is the good spot to add monitoring

}

