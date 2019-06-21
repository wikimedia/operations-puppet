class snapshot::dumps::timechecker(
    $dumpsbasedir = undef,
    $xmldumpsuser = undef,
)  {
    $repodir = $snapshot::dumps::dirs::repodir
    $wikis = ['arwiki', 'dewiki', 'commonswiki', 'frwiki', 'eswiki',
              'hewiki', 'huwiki', 'itwiki', 'jawiki', 'metawiki',
              'nlwiki', 'plwiki', 'ptwiki', 'ruwiki', 'zhwiki',
              'enwiki', 'svwiki', 'wikidatawiki']
    $wikis_list = join($wikis, ',')

    $apachedir = $snapshot::dumps::dirs::apachedir
    $dblist = "${apachedir}/dblists/all.dblist"

    cron { 'dumps-timechecker':
        ensure      => 'present',
        environment => 'MAILTO=ops-dumps@wikimedia.org',
        command     => "cd ${repodir}; python3 show_runtimes.py -d ${dumpsbasedir} -W ${wikis_list}; python3 show_runtimes.py -d ${dumpsbasedir} -j meta-history-bz2 -s 40 -w ${dblist}",
        user        => $xmldumpsuser,
        minute      => '10',
        hour        => '1',
        monthday    => [1, 20],
    }
}
