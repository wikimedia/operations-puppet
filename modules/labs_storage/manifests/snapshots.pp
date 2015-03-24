define labs_storage::snapshots(
    $filesystem,
    $hour          = '*',
    $minute        = '5',
)
{
    cron { "snapshot-$filesystem":
        command => "/usr/local/sbin/manage-snapshots '$filesystem'",
        user    => 'root',
        hour    => $hour,
        minute  => $minute,
        require => File['/usr/local/sbin/manage-snapshots'],
    }

    # This is the good spot to add monitoring

}

