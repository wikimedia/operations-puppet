class snapshot::dumps::configs {
    include ::snapshot::dumps::dirs

    $dblistsdir = $snapshot::dumps::dirs::dblistsdir
    $apachedir = $snapshot::dumps::dirs::apachedir
    $confsdir = $snapshot::dumps::dirs::confsdir

    $enchunkhistory1 = '30303,58141,112065,152180,212624,327599,375779,522388,545343,710090,880349,1113575,1157158,1547206'
    $enchunkhistory2 = '1773248,2021218,2153807,2427469,2634193,2467421, 2705827,2895677,3679790,3449365,4114387,4596259,6533612'

    $config = {
        smallwikis => {
            dblist        => "${apachedir}/dblists/all.dblist",
            skipdblist    => "${dblistsdir}/skip.dblist",
            keep          => '10',
            chunksEnabled => '0',
        },
        bigwikis => {
            dblist           => "${dblistsdir}/bigwikis.dblist",
            skipdblist       => "${dblistsdir}/skipnone.dblist",
            keep             => '8',
            chunksEnabled    => '1',
            recombineHistory => '0',
            wikis            => {
                ruwiki => {
                    pagesPerChunkHistory  => '311181,1142420,1627923,3122803',
                    pagesPerChunkAbstract => '1200000',
                    chunksForAbstract     => '4',
                    checkpointTime        => '720',
                },
                eswiki => {
                    pagesPerChunkHistory  => '229078,854374,2324057,3860337',
                    pagesPerChunkAbstract => '1500000',
                    chunksForAbstract     => '4',
                    checkpointTime        => '720',
                },
                dewiki => {
                    pagesPerChunkHistory  => '425449,1451596,3087456,4274631',
                    pagesPerChunkAbstract => '2000000',
                    chunksForAbstract     => '4',
                    checkpointTime        => '720',
                },
                ptwiki => {
                    pagesPerChunkHistory  => '158756,789502,1361027,2669897',
                    pagesPerChunkAbstract => '1000000',
                    chunksForAbstract     => '4',
                },
                plwiki => {
                    pagesPerChunkHistory  => '235373,514490,957079,1923498',
                    pagesPerChunkAbstract => '800000',
                    chunksForAbstract     => '4',
                },
                nlwiki => {
                    pagesPerChunkHistory  => '224145,552515,1098243,2570924',
                    pagesPerChunkAbstract => '1000000',
                    chunksForAbstract     => '4',
                },
                frwiki => {
                    pagesPerChunkHistory  => '412303,1235589,2771967,5313378',
                    pagesPerChunkAbstract => '1900000',
                    chunksForAbstract     => '4',
                    checkpointTime        => '720',
                },
                itwiki => {
                    pagesPerChunkHistory  => '442893,1049883,1381705,2929437',
                    pagesPerChunkAbstract => '1200000',
                    chunksForAbstract     => '4',
                    checkpointTime        => '720',
                },
                jawiki => {
                  pagesPerChunkHistory  => '168815,480631,943865,1760565',
                    pagesPerChunkAbstract => '800000',
                    chunksForAbstract     => '4',
                    checkpointTime        => '720',
                },
                commonswiki => {
                    pagesPerChunkHistory  => '6457504,9672260,12929298,17539944',
                    pagesPerChunkAbstract => '11000000',
                    chunksForAbstract     => '4',
                    checkpointTime        => '720',
                },
                wikidatawiki => {
                    pagesPerChunkHistory  => '2421529,4883997,8784997,8199134',
                    pagesPerChunkAbstract => '5800000',
                    chunksForAbstract     => '4',
                    checkpointTime        => '720',
                    orderrevs             => '1',
                    minpages              => '10',
                    maxrevs               => '20000',
                },
                zhwiki => {
                    pagesPerChunkHistory  => '231819,564192,1300322,3112369',
                    pagesPerChunkAbstract => '1300000',
                    chunksForAbstract     => '4',
                },
                metawiki => {
                    pagesPerChunkHistory  => '823386,2594392,3242670,3284506',
                    pagesPerChunkAbstract => '2500000',
                    chunksForAbstract     => '4',
                },
            },
        },
        hugewikis => {
            dblist           => "${dblistsdir}/hugewikis.dblist",
            skipdblist       => "${dblistsdir}/skipnone.dblist",
            keep             => '7',
            chunksEnabled    => '1',
            recombineHistory => '0',
            checkpointTime   => '720',
            wikis => {
                enwiki => {
                    jobsperbatch          => 'xmlstubsdump=14',
                  pagesPerChunkHistory  => "${enchunkhistory1},${enchunkhistory2}",
                    pagesPerChunkAbstract => '2000000',
                },
            },
        },
        monitor => {
            dblist        => "${apachedir}/dblists/all.dblist",
            skipdblist    => "${dblistsdir}/skipmonitor.dblist",
            keep          => '30',
            chunksEnabled => '0',
        },
        media => {
            dblist        => "${apachedir}/dblists/all.dblist",
            skipdblist    => "${dblistsdir}/skipmonitor.dblist,${dblistsdir}/globalusage.dblist",
            keep          => '30',
            chunksEnabled => '0',
        },
    }

    snapshot::dumps::wikiconf { 'wikidump.conf':
        configtype => 'smallwikis',
        config     => $config,
    }
    snapshot::dumps::wikiconf { 'wikidump.conf.bigwikis':
        configtype => 'bigwikis',
        config     => $config,
    }
    snapshot::dumps::wikiconf { 'wikidump.conf.hugewikis':
        configtype => 'hugewikis',
        config     => $config,
    }
    snapshot::dumps::wikiconf { 'wikidump.conf.monitor':
        configtype => 'monitor',
        config     => $config,
    }
    snapshot::dumps::wikiconf { 'wikidump.conf.media':
        configtype => 'media',
        config     => $config,
    }

    file { "${confsdir}/table_jobs.yaml":
        ensure => 'present',
        path   => "${confsdir}/table_jobs.yaml",
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/snapshot/dumps/table_jobs.yaml',
    }
}
