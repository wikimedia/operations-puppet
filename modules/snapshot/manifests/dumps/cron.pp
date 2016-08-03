class snapshot::dumps::cron(
    $enable = true,
    $user   = undef,
) {
    include snapshot::dumps::dirs

    if ($enable) {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    $maxjobs = hiera('snapshot::dumps::maxjobs', 28)
    file { '/usr/local/bin/fulldumps.sh':
        ensure  => 'present',
        path    => '/usr/local/bin/fulldumps.sh',
        mode    => '0755',
        owner   => root,
        group   => root,
        content => template('snapshot/dumps/fulldumps.sh.erb'),
    }

    $logdir = '/var/log/dumps'
    file { $logdir:
      ensure => 'directory',
      path   => '/var/log/dumps',
      mode   => '0755',
      owner  => $user,
    }

    file { '/etc/logrotate.d/xmldumps':
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/snapshot/dumps/logrotate.xmldumps',
    }

    $runtype = hiera('snapshot::dumps::runtype', 'regular')

    $fullcommand = "/usr/local/bin/fulldumps.sh 01 14 ${runtype}"
    $partialcommand = "/usr/local/bin/fulldumps.sh 20 25 ${runtype}"
    $output = "${logdir}/xmldumps_\$(date -u +\%s).log"

    # fixme there is an implicit dependency on
    # wikidump.conf.* plus some stage files, make explicit

    cron { 'fulldumps_rest':
        ensure      => 'present',
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        user        => $user,
        command     => "${fullcommand} full > ${output}",
        minute      => '05',
        hour        => [8, 20],
        monthday    => '01-14',
    }

    cron { 'partialdumps_rest':
        ensure      => 'present',
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        user        => $user,
        command     => "${partialcommand} full > ${output}",
        minute      => '05',
        hour        => [8, 20],
        monthday    => '20-25',
    }


}
