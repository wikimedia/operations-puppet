#

class { 'bacula::client':
    director        => 'dir.example.com',
    catalog         => 'example',
    file_retention  => '60 days',
    job_retention   => '6 months',
}

bacula::client::job { "rootfs-ourdefaults":
    fileset     => 'root',
    jobdefaults => 'ourdefaults',
}

bacula::client::job { "varfs-ourdefaults":
    fileset     => 'root',
    jobdefaults => 'ourdefaults',
}
