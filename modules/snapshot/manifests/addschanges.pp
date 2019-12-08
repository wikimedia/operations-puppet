class snapshot::addschanges(
    $user      = undef,
    $filesonly = false,
) {
    $repodir = $snapshot::dumps::dirs::repodir
    $confsdir = $snapshot::dumps::dirs::confsdir
    $apachedir = $snapshot::dumps::dirs::apachedir
    $dblistsdir = $snapshot::dumps::dirs::dblistsdir
    $templsdir = $snapshot::dumps::dirs::templsdir
    $cronsdir = $snapshot::dumps::dirs::cronsdir

    file { "${confsdir}/addschanges.conf":
        ensure  => 'present',
        path    => "${confsdir}/addschanges.conf",
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
        content => template('snapshot/addschanges.conf.erb'),
    }
    file { "${templsdir}/incrs-index.html":
        ensure => 'present',
        path   => "${templsdir}/incrs-index.html",
        mode   => '0644',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/snapshot/addschanges/incrs-index.html',
    }

    if !$filesonly {
        cron { 'adds-changes':
            ensure      => 'present',
            environment => 'MAILTO=ops-dumps@wikimedia.org',
            user        => $user,
            command     => "python3 ${repodir}/generatemiscdumps.py --configfile ${confsdir}/addschanges.conf --dumptype incrdumps --quiet",
            minute      => '50',
            hour        => '20',
        }
    }
}
