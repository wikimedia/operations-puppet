class snapshot::cron::categoriesrdf(
    $user      = undef,
    $filesonly = false,
) {
    $confsdir = $snapshot::dumps::dirs::confsdir
    $apachedir =  $snapshot::dumps::dirs::apachedir

    file { '/var/log/categoriesrdf':
        ensure => 'directory',
        mode   => '0644',
        owner  => $user,
    }

    file { '/usr/local/bin/dumpcategoriesrdf-shared.sh':
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/snapshot/cron/dumpcategoriesrdf-shared.sh',
    }

    $scriptpath = '/usr/local/bin/dumpcategoriesrdf.sh'
    file { $scriptpath:
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/snapshot/cron/dumpcategoriesrdf.sh',
        require => File['/usr/local/bin/dumpcategoriesrdf-shared.sh'],
    }

    if !$filesonly {
        logrotate::conf { 'categoriesrdf':
            ensure => present,
            source => 'puppet:///modules/snapshot/cron/logrotate.categoriesrdf',
        }

        cron { 'categoriesrdf-dump':
            ensure      => absent,
            command     => "${scriptpath} --config ${confsdir}/wikidump.conf.other --list ${apachedir}/dblists/categories-rdf.dblist",
            environment => 'MAILTO=ops-dumps@wikimedia.org',
            user        => $user,
            minute      => '0',
            hour        => '20',
            weekday     => '6',
            require     => File[$scriptpath],
        }
        systemd::timer::job { 'categoriesrdf-dump':
            ensure             => present,
            description        => 'Regular jobs to build rdf snapshot of categories',
            user               => $user,
            monitoring_enabled => false,
            send_mail          => true,
            environment        => {'MAILTO' => 'ops-dumps@wikimedia.org'},
            command            => "${scriptpath} --config ${confsdir}/wikidump.conf.other --list ${apachedir}/dblists/categories-rdf.dblist",
            interval           => {'start' => 'OnCalendar', 'interval' => 'Sat *-*-* 20:0:0'},
            require            => File[$scriptpath],
        }
    }

    $scriptpath_daily = '/usr/local/bin/dumpcategoriesrdf-daily.sh'
    file { $scriptpath_daily:
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/snapshot/cron/dumpcategoriesrdf-daily.sh',
        require => File['/usr/local/bin/dumpcategoriesrdf-shared.sh'],
    }

    if !$filesonly {
        cron { 'categoriesrdf-dump-daily':
            ensure      => absent,
            command     => "${scriptpath_daily} --config ${confsdir}/wikidump.conf.other --list ${apachedir}/dblists/categories-rdf.dblist",
            environment => 'MAILTO=ops-dumps@wikimedia.org',
            user        => $user,
            minute      => '0',
            hour        => '5',
            require     => File[$scriptpath_daily],
        }
        systemd::timer::job { 'categoriesrdf-dump-daily':
            ensure             => present,
            description        => 'Regular jobs to build daily rdf snapshot of categories',
            user               => $user,
            monitoring_enabled => false,
            send_mail          => true,
            environment        => {'MAILTO' => 'ops-dumps@wikimedia.org'},
            command            => "${scriptpath_daily} --config ${confsdir}/wikidump.conf.other --list ${apachedir}/dblists/categories-rdf.dblist",
            interval           => {'start' => 'OnCalendar', 'interval' => '*-*-* 5:0:0'},
            require            => File[$scriptpath_daily],
        }
    }
}

