class snapshot::cron::pagetitles(
    $user      = undef,
    $filesonly = false,
) {
    $cronsdir = $snapshot::dumps::dirs::cronsdir
    $repodir = $snapshot::dumps::dirs::repodir
    $confsdir = $snapshot::dumps::dirs::confsdir

    if !$filesonly {
        systemd::timer::job { 'pagetitles-ns0':
            ensure             => present,
            description        => 'Regular jobs to build snapshot of page titles of main namespace',
            user               => $user,
            monitoring_enabled => false,
            send_mail          => true,
            environment        => {'MAILTO' => 'ops-dumps@wikimedia.org'},
            working_directory  => $repodir,
            command            => "/usr/bin/python3 onallwikis.py --configfile ${confsdir}/wikidump.conf.dumps:monitor  --filenameformat '{w}-{d}-all-titles-in-ns-0.gz' --outdir '${cronsdir}/pagetitles/{d}' --query \"'select page_title from page where page_namespace=0;'\"",
            interval           => {'start' => 'OnCalendar', 'interval' => '*-*-* 8:10:0'},
        }

        systemd::timer::job { 'pagetitles-ns6':
            ensure             => present,
            description        => 'Regular jobs to build snapshot of page titles of file namespace',
            user               => $user,
            monitoring_enabled => false,
            send_mail          => true,
            environment        => {'MAILTO' => 'ops-dumps@wikimedia.org'},
            working_directory  => $repodir,
            command            => "/usr/bin/python3 onallwikis.py --configfile ${confsdir}/wikidump.conf.dumps:monitor  --filenameformat '{w}-{d}-all-media-titles.gz' --outdir '${cronsdir}/mediatitles/{d}' --query \"'select page_title from page where page_namespace=6;'\"",
            interval           => {'start' => 'OnCalendar', 'interval' => '*-*-* 8:50:0'},
        }
    }
}
