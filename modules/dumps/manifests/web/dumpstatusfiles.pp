class dumps::web::dumpstatusfiles(
    $xmldumpsdir = undef,
) {
    file { '/usr/local/bin/unpack-dumpstatusfiles.sh':
        ensure => 'present',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dumps/web/unpack-dumpstatusfiles.sh',
    }

    # interval passed to script should match interval cron job runs;
    # check every interval minutes for a new tarball of status files
    # and unpack them
    cron { 'update-dump-statusfiles':
        ensure      => 'present',
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        command     => "/bin/bash /usr/local/bin/unpack-dumpstatusfiles.sh --xmldumpsdir ${xmldumpsdir} --newer 5",
        user        => root,
        minute      => '*/5',
        require     => File['/usr/local/bin/unpack-dumpstatusfiles.sh'],
    }

}
