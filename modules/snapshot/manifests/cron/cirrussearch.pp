class snapshot::cron::cirrussearch(
    $user   = undef,
) {
    $confsdir = $snapshot::dumps::dirs::confsdir

    file { '/var/log/cirrusdump':
        ensure => 'directory',
        mode   => '0644',
        owner  => $user,
    }

    file { '/etc/logrotate.d/cirrusdump':
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/snapshot/cron/logrotate.cirrusdump',
    }

    $scriptPath = '/usr/local/bin/dumpcirrussearch.sh'
    file { $scriptPath:
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
        content => template('snapshot/cron/dumpcirrussearch.sh.erb'),
    }

    cron { 'cirrussearch-dump':
        ensure      => 'present',
        command     => "${scriptPath} --config ${confsdir}/wikidump.conf",
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        user        => $user,
        minute      => '15',
        hour        => '16',
        weekday     => '1',
        require     => File[$scriptPath],
    }
}

