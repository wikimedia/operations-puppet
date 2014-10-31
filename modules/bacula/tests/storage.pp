#

class { 'bacula::storage':
    director           => 'dir.example.com',
    sd_max_concur_jobs => 5,
    sqlvariant         => 'mysql',
}

bacula::storage::device { 'FileStorage':
    device_type     => 'File',
    media_type      => 'File',
    archive_device  => '/srv/backups',
    max_concur_jobs => 2,
}

bacula::storage::device { 'Tapes':
    device_type     => 'Tape',
    media_type      => 'LTO4',
    archive_device  => '/dev/nst0',
    max_concur_jobs => 2,
    spool_dir       => '/tmp/spool',
    max_spool_size  => '32212254720',
}
