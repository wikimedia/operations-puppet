class snapshot::cron::cirrussearch(
    $user = undef,
) {
    file { '/var/log/cirrusdump':
        ensure => 'directory',
        mode   => '0644',
        owner  => $user,
    }

    logrotate::conf { 'cirrusdump':
        ensure => present,
        source => 'puppet:///modules/snapshot/cron/logrotate.cirrusdump',
    }

    $scriptpath = '/usr/local/bin/dumpcirrussearch.sh'
    file { $scriptpath:
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/snapshot/cron/dumpcirrussearch.sh',
    }

    cron { 'cirrussearch-dump':
        ensure      => 'present',
        command     => "${scriptpath} --config ${confsdir}/wikidump.conf",
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        user        => $user,
        minute      => '15',
        hour        => '16',
        weekday     => '1',
        require     => [ File[$scriptpath], Class['snapshot::dirs'] ],
    }
}

