#

class { 'bacula::client':
    director       => 'dir.example.com',
    catalog        => 'example',
    file_retention => '60 days',
    job_retention  => '6 months',
}

bacula::client::job { 'rootfs-ourdefaults':
    fileset     => 'root',
    jobdefaults => 'ourdefaults',
}

bacula::client::job { 'varfs-ourdefaults':
    fileset     => 'root',
    jobdefaults => 'ourdefaults',
}

bacula::client::mysql-bpipe { 'mysqldump':
    per_database          => false,
    xtrabackup            => false,
    mysqldump_innodb_only => false,
}

bacula::client::mysql-bpipe { 'mysqldump_transaction':
    per_database          => false,
    xtrabackup            => false,
    mysqldump_innodb_only => true,
}

bacula::client::mysql-bpipe { 'mysqldump_perdb':
    per_database          => true,
    xtrabackup            => false,
    mysqldump_innodb_only => true,
}

bacula::client::mysql-bpipe { 'xtrabackup':
    per_database => false,
    xbstream_dir => '/a/xbstream',
    xtrabackup   => true,
}

bacula::client::mysql-bpipe { 'xtrabackup_slave_perdb':
    per_database => true,
    xbstream_dir => '/b/xbstream',
    xtrabackup   => true,
}
