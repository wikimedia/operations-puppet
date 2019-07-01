class snapshot::dumps::cron(
    $enable = true,
    $user   = undef,
    $maxjobs = undef,
    $runtype = undef,
) {
    if ($enable) {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    file { '/usr/local/bin/fulldumps.sh':
        ensure => 'present',
        path   => '/usr/local/bin/fulldumps.sh',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/snapshot/dumps/fulldumps.sh',
    }

    file { '/var/log/dumps':
      ensure => 'directory',
      path   => '/var/log/dumps',
      mode   => '0755',
      owner  => $user,
    }

    # fixme there is an implicit dependency on
    # wikidump.conf.dumps plus some stage files, make explicit

    cron { 'fulldumps_rest':
        ensure      => 'present',
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        user        => $user,
        command     => "/usr/local/bin/fulldumps.sh 01 14 ${runtype} full ${maxjobs} > /dev/null",
        minute      => '05',
        hour        => [8, 20],
        monthday    => '02-14',
    }

    cron { 'partialdumps_rest':
        ensure      => 'present',
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        user        => $user,
        command     => "/usr/local/bin/fulldumps.sh 20 25 ${runtype} partial ${maxjobs} > /dev/null",
        minute      => '05',
        hour        => [8, 20],
        monthday    => '20-25',
    }

}
