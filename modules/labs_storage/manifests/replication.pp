define labs_storage::replication(
    $filesystem,
    $destination,
    $hour          = '1',
    $minute        = '11',
)
{
    cron { "replicate-$filesystem":
        command => "/usr/local/sbin/storage-replicate '$filesystem' '$destination'",
        user    => 'root',
        hour    => $hour,
        minute  => $minute,
        require => Class['labs_storage::server'],
    }

    # This is the good spot to add monitoring

}

