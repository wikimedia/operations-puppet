class snapshot::addschanges(
    $user      = undef,
    $filesonly = false,
) {
    $repodir = $snapshot::dumps::dirs::repodir
    $confsdir = $snapshot::dumps::dirs::confsdir
    $apachedir = $snapshot::dumps::dirs::apachedir
    $dblistsdir = $snapshot::dumps::dirs::dblistsdir
    $templsdir = $snapshot::dumps::dirs::templsdir
    $systemdjobsdir = $snapshot::dumps::dirs::systemdjobsdir

    # for adds/changes dumps in production
    snapshot::addschangesconf { 'addschanges.conf':
        alldblist => 'all.dblist',
    }

    # for adds/changes dumps in deployment-prep
    snapshot::addschangesconf { 'addschanges.conf.labs':
        alldblist => 'all-labs.dblist',
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
        systemd::timer::job { 'adds-changes':
            ensure       => 'present',
            description  => 'Regular jobs to generate misc dumps',
            user         => $user,
            command      => "/usr/bin/python3 ${repodir}/generatemiscdumps.py --configfile ${confsdir}/addschanges.conf --dumptype incrdumps --quiet",
            send_mail    => true,
            send_mail_to => 'ops-dumps@wikimedia.org',
            interval     => {'start' => 'OnCalendar', 'interval' => '*-*-* 20:50:00'},
        }
    }
}
