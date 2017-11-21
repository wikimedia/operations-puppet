class dumps::web::statusfiles(
    $xmldumpsdir = undef,
) {
    file { '/usr/local/bin/unpack-statusfiles.sh':
        ensure => 'present',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/dumps/generation/unpack-statusfiles.sh',
    }

    # interval passed to script should match interval cron job runs;
    # check every interval minutes for a new tarball of status files
    # and unpack them
    cron { 'update-dump-statusfiles':
        ensure      => 'present',
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        command     => "/bin/bash /usr/local/bin/unpack-statusfiles.sh --xmldumpsdir ${xmldumpsdir} --interval 5",
        user        => root,
        minute      => '*/5',
        require     => File['/usr/local/bin/unpack-statusfiles.sh'],
    }

}
