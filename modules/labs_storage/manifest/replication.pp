define labs_storage::replication(
    $filesystem,
    $destination,
    $hour          = '1',
    $minute        = '11',
)
{
    if ! $filesystem {
        fail('Parameter $filesystem must be specified')
    }

    if ! $destination {
        fail('Parameter $destination must be specified')
    }

    cron { "replicate-$filesystem":
        command => "/usr/local/sbin/storage-replicate '$filesystem' '$destination'",
        user    => 'root',
        hour    => $hour,
        minute  => $minute,
        require => File['/usr/local/sbin/storage-replicate'],
    }

    # This is the good spot to add monitoring

}

