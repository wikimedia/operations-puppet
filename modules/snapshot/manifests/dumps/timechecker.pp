class snapshot::dumps::timechecker(
    $dumpsbasedir = undef,
    $xmldumpsuser = undef,
)  {
    $repodir = $snapshot::dumps::dirs::repodir
    $wikis = ['arwiki', 'dewiki', 'commonswiki', 'frwiki', 'eswiki',
              'hewiki', 'huwiki', 'itwiki', 'jawiki', 'kowiki', 'metawiki',
              'nlwiki', 'plwiki', 'ptwiki', 'ruwiki', 'zhwiki',
              'enwiki', 'svwiki', 'ukwiki', 'viwiki', 'wikidatawiki']
    $wikis_list = join($wikis, ',')

    $apachedir = $snapshot::dumps::dirs::apachedir
    $dblist = "${apachedir}/dblists/all.dblist"

    systemd::timer::job { 'dumps-timecheck-wikilist':
        ensure                  => present,
        description             => 'Show runtimes for dumps (wiki list)',
        user                    => $xmldumpsuser,
        send_mail               => true,
        send_mail_to            => 'ops-dumps@wikimedia.org',
        send_mail_only_on_error => false,
        command                 => "/usr/bin/python3 show_runtimes.py -d ${dumpsbasedir} -W ${wikis_list}",
        working_directory       => $repodir,
        interval                => {'start' => 'OnCalendar', 'interval' => '*-*-1,20 01:10:00'}
    }

    systemd::timer::job { 'dumps-timecheck-dblist':
        ensure                  => present,
        description             => 'Show runtimes for dumps (dblist)',
        user                    => $xmldumpsuser,
        send_mail               => true,
        send_mail_to            => 'ops-dumps@wikimedia.org',
        send_mail_only_on_error => false,
        command                 => "/usr/bin/python3 show_runtimes.py -d ${dumpsbasedir} -j meta-history-bz2 -s 40 -w ${dblist}",
        working_directory       => $repodir,
        interval                => {'start' => 'OnCalendar', 'interval' => '*-*-1,20 02:10:00'}
    }
}
