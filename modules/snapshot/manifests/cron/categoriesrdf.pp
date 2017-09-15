class snapshot::cron::categoriesrdf(
    $user   = undef,
) {
    $confsdir = $snapshot::dumps::dirs::confsdir
    $apachedir =  $snapshot::dumps::dirs::apachedir

    file { '/var/log/categoriesrdf':
        ensure => 'directory',
        mode   => '0644',
        owner  => $user,
    }

    logrotate::conf { 'categoriesrdf':
        ensure => present,
        source => 'puppet:///modules/snapshot/cron/logrotate.categoriesrdf',
    }

    file { '/usr/local/bin/dumpcategoriesrdf-shared.sh':
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/snapshot/cron/dumpcategoriesrdf-shared.sh',
    }


    $scriptpath = '/usr/local/bin/dumpcategoriesrdf.sh'
    file { $scriptpath:
        mode        => '0755',
        owner       => 'root',
        group       => 'root',
        source      => 'puppet:///modules/snapshot/cron/dumpcategoriesrdf.sh',
        require     => File['/usr/local/bin/dumpcategoriesrdf-shared.sh'],
    }

    cron { 'categoriesrdf-dump':
        ensure      => 'present',
        command     => "${scriptpath} --config ${confsdir}/wikidump.conf --list ${apachedir}/dblists/categories-rdf.dblist",
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        user        => $user,
        minute      => '0',
        hour        => '20',
        weekday     => '6',
        require     => File[$scriptpath],
    }

    $scriptpath_daily = '/usr/local/bin/dumpcategoriesrdf-daily.sh'
    file { $scriptpath_daily:
        mode        => '0755',
        owner       => 'root',
        group       => 'root',
        source      => 'puppet:///modules/snapshot/cron/dumpcategoriesrdf-daily.sh',
        require     => File['/usr/local/bin/dumpcategoriesrdf-shared.sh'],
    }

    cron { 'categoriesrdf-dump-daily':
        ensure      => 'present',
        command     => "${scriptpath_daily} --config ${confsdir}/wikidump.conf --list ${apachedir}/dblists/categories-rdf.dblist",
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        user        => $user,
        minute      => '0',
        hour        => '5',
        require     => File[$scriptpath_daily],
    }
}

