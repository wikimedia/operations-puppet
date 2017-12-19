class snapshot::dumps::configs {
    $dblistsdir = $snapshot::dumps::dirs::dblistsdir
    $apachedir = $snapshot::dumps::dirs::apachedir
    $confsdir = $snapshot::dumps::dirs::confsdir
    $publicdir = $snapshot::dumps::dirs::xmldumpspublicdir
    $privatedir = $snapshot::dumps::dirs::xmldumpsprivatedir
    $tempdir = $snapshot::dumps::dirs::dumpstempdir

    $enchunkhistory1 = '30303,58141,112065,152180,212624,327599,375779,522388,545343,710090,880349,1113575,1157158,1547206'
    $enchunkhistory2 = '1773248,2021218,2153807,2427469,2634193,2467421,2705827,2895677,3679790,3449365,4114387,4596259,6533612'

    $wikidatachunkhistory1 = '235321,350222,430401,531179,581039,600373,762298,826545,947305,1076978,1098243,993874,1418919,2399950'
    $wikidatachunkhistory2 = '2587436,951696,942913,837759,1568292,1293747,2018593,1461235,1797642,1487121,2012246,874850,1486799'

    $config = {
        allwikis => {
            global => {
                dblist        => "${apachedir}/dblists/all.dblist",
                skipdblist    => "${dblistsdir}/skip.dblist",
                keep          => '10',
                chunksEnabled => '0',
            },
            big => {
                dblist            => "${dblistsdir}/bigwikis.dblist",
                skipdblist        => "${dblistsdir}/skipnone.dblist",
                keep              => '8',
                chunksEnabled     => '1',
                chunksForAbstract => '4',
                checkpointTime    => '720',
                recombineHistory  => '0',
                revsPerJob        => '1500000',
                retryWait         => '30',
                maxRetries        => '3',
                revsMargin        => '100',
                fixeddumporder    => '1',
                wikis => {
                    ruwiki => {
                        pagesPerChunkHistory  => '311181,1142420,1627923,3122803',
                        pagesPerChunkAbstract => '1200000',
                    },
                    eswiki => {
                        pagesPerChunkHistory  => '229078,854374,2324057,3860337',
                        pagesPerChunkAbstract => '1500000',
                    },
                    dewiki => {
                        pagesPerChunkHistory  => '425449,1451596,3087456,4274631',
                        pagesPerChunkAbstract => '2000000',
                    },
                    ptwiki => {
                        pagesPerChunkHistory  => '158756,789502,1361027,2669897',
                        pagesPerChunkAbstract => '1000000',
                    },
                    plwiki => {
                        pagesPerChunkHistory  => '235373,514490,957079,1923498',
                        pagesPerChunkAbstract => '800000',
                    },
                    nlwiki => {
                        pagesPerChunkHistory  => '224145,552515,1098243,2570924',
                        pagesPerChunkAbstract => '1000000',
                    },
                    frwiki => {
                        pagesPerChunkHistory  => '412303,1235589,2771967,5313378',
                        pagesPerChunkAbstract => '1900000',
                    },
                    itwiki => {
                        pagesPerChunkHistory  => '442893,1049883,1381705,2929437',
                        pagesPerChunkAbstract => '1200000',
                    },
                    jawiki => {
                        pagesPerChunkHistory  => '168815,480631,943865,1760565',
                        pagesPerChunkAbstract => '800000',
                    },
                    commonswiki => {
                        pagesPerChunkHistory  => '6457504,9672260,12929298,17539944',
                        pagesPerChunkAbstract => '11000000',
                    },
                    zhwiki => {
                        pagesPerChunkHistory  => '231819,564192,1300322,3112369',
                        pagesPerChunkAbstract => '1300000',
                    },
                    metawiki => {
                        pagesPerChunkHistory  => '823386,2594392,3242670,3284506',
                        pagesPerChunkAbstract => '2500000',
                    },
                },
            },
            en => {
                dblist            => "${dblistsdir}/enwiki.dblist",
                skipdblist        => "${dblistsdir}/skipnone.dblist",
                jobsperbatch      => 'xmlstubsdump=9,abstractsdump=9',
                keep              => '7',
                chunksEnabled     => '1',
                chunksForAbstract => '27',
                recombineHistory  => '0',
                checkpointTime    => '720',
                revsPerJob        => '1500000',
                retryWait         => '30',
                maxRetries        => '3',
                revsMargin        => '100',
                maxrevs           => '20000',
                wikis => {
                    enwiki => {
                        pagesPerChunkHistory  => "${enchunkhistory1},${enchunkhistory2}",
                    },
                },
            },
            wd => {
                dblist            => "${dblistsdir}/wikidatawiki.dblist",
                skipdblist        => "${dblistsdir}/skipnone.dblist",
                jobsperbatch      => 'xmlstubsdump=9,abstractsdump=9',
                keep              => '7',
                chunksEnabled     => '1',
                chunksForAbstract => '27',
                recombineHistory  => '0',
                checkpointTime    => '720',
                revsPerJob        => '1500000',
                retryWait         => '30',
                maxRetries        => '3',
                revsMargin        => '100',
                maxrevs           => '20000',
                wikis => {
                    wikidatawiki => {
                        pagesPerChunkHistory  => "${wikidatachunkhistory1},${$wikidatachunkhistory2}",
                        orderrevs             => '1',
                        minpages              => '10',
                    },
                },
            },
            monitor => {
                skipdblist    => "${dblistsdir}/skipmonitor.dblist",
            },
            media => {
                skipdblist    => "${dblistsdir}/skipmonitor.dblist,${dblistsdir}/globalusage.dblist",
            }
        },
    }

    # for xml/sql dumps running on dumpsdata host
    snapshot::dumps::wikiconf { 'wikidump.conf.dumps':
        configtype => 'allwikis',
        config     => $config,
        publicdir  => $publicdir,
        privatedir => $privatedir,
        tempdir    => $tempdir,
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
