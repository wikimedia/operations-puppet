class snapshot::cron::categoriesrdf(
    $user   = undef,
) {
    $confsdir = $snapshot::dumps::dirs::confsdir
    $dblistsdir = $snapshot::dumps::dirs::dblistsdir
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

    $scriptpath = '/usr/local/bin/dumpcategoriesrdf.sh'
    file { $scriptpath:
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/snapshot/cron/dumpcategoriesrdf.sh',
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
}

