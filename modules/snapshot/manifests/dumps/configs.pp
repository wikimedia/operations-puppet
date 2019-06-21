class snapshot::dumps::configs(
    $php = undef,
) {
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
                adminmail     => 'ops-dumps@wikimedia.org',
                retryWait     => '30',
                maxRetries    => '3',
            },
            big => {
                dblist            => "${dblistsdir}/bigwikis.dblist",
                skipdblist        => "${dblistsdir}/skipnone.dblist",
                keep              => '8',
                chunksEnabled     => '1',
                chunksForAbstract => '6',
                chunksForPagelogs => '6',
                checkpointTime    => '720',
                recombineHistory  => '0',
                revsPerJob        => '1500000',
                revsMargin        => '100',
                fixeddumporder    => '1',
                lbzip2threads     => '3',
                lbzip2forhistory  => '1',
                wikis => {
                    ruwiki => {
                        pagesPerChunkHistory  => '204180,713334,1020881,1460226,2071097,1997756',
                    },
                    eswiki => {
                        pagesPerChunkHistory  => '143637,453697,1022338,2461188,2343955,2079372',
                    },
                    dewiki => {
                        pagesPerChunkHistory  => '262468,833472,1824108,2546227,2875893,2015418',
                    },
                    ptwiki => {
                        pagesPerChunkHistory  => '95099,347371,986019,1093673,1840534,1392584',
                    },
                    plwiki => {
                        pagesPerChunkHistory  => '169750,340912,545648,775198,1238885,1228962',
                    },
                    nlwiki => {
                        pagesPerChunkHistory  => '123351,327622,547504,892061,1623038,1554657',
                    },
                    frwiki => {
                        pagesPerChunkHistory  => '275787,651758,1589336,2075474,2901773,4250595',
                    },
                    itwiki => {
                        pagesPerChunkHistory  => '277091,780781,902023,1188047,1865256,2470232',
                    },
                    jawiki => {
                        pagesPerChunkHistory  => '106178,244607,452382,738003,993022,1262938',
                    },
                    commonswiki => {
                        pagesPerChunkHistory  => '7049914,9227378,11916955,13452135,15431846,12516670',
                    },
                    zhwiki => {
                        pagesPerChunkHistory  => '162886,381758,609973,1616469,1960353,1437788',
                    },
                    metawiki => {
                        pagesPerChunkHistory  => '321600,1887125,2144409,2584802,2550664,1127385',
                    },
                    hewiki => {
                        pagesPerChunkHistory  => '54634,150485,262147,348019,456051,338308',
                    },
                    huwiki => {
                        pagesPerChunkHistory  => '58601,139602,207871,286244,424120,457034',
                    },
                    arwiki => {
                        pagesPerChunkHistory  => '186249,444457,797927,988530,1342181,970511',
                    },
                    svwiki => {
                        pagesPerChunkHistory  => '149665,488964,999678,1911420,2515721,2250556',
                    },
                },
            },
            en => {
                dblist            => "${dblistsdir}/enwiki.dblist",
                skipdblist        => "${dblistsdir}/skipnone.dblist",
                jobsperbatch      => 'xmlstubsdump=9,abstractsdump=9,xmlpagelogsdump=9',
                keep              => '7',
                chunksEnabled     => '1',
                chunksForAbstract => '27',
                chunksForPagelogs => '27',
                recombineHistory  => '0',
                checkpointTime    => '720',
                revsPerJob        => '1500000',
                revsMargin        => '100',
                maxrevs           => '20000',
                lbzip2threads     => '10',
                wikis => {
                    enwiki => {
                        pagesPerChunkHistory  => "${enchunkhistory1},${enchunkhistory2}",
                        lbzip2forhistory      => '1',
                    },
                },
            },
            wd => {
                dblist               => "${dblistsdir}/wikidatawiki.dblist",
                skipdblist           => "${dblistsdir}/skipnone.dblist",
                jobsperbatch         => 'xmlstubsdump=9,abstractsdump=9,xmlpagelogsdump=9',
                keep                 => '7',
                chunksEnabled        => '1',
                chunksForAbstract    => '27',
                chunksForPagelogs    => '27',
                recombineMetaCurrent => '0',
                recombineHistory     => '0',
                checkpointTime       => '720',
                revsPerJob           => '1500000',
                revsMargin           => '100',
                maxrevs              => '20000',
                lbzip2threads        => '10',
                wikis => {
                    wikidatawiki => {
                        pagesPerChunkHistory  => "${wikidatachunkhistory1},${$wikidatachunkhistory2}",
                        minpages              => '10',
                        lbzip2forhistory      => '1',
                    },
                },
            },
            monitor => {
                skipdblist    => "${dblistsdir}/skipmonitor.dblist",
            },
            media => {
                skipdblist    => "${dblistsdir}/skipmonitor.dblist,${dblistsdir}/globalusage.dblist",
            },
        },
    }

    $labsconfig = {
        allwikis => {
            global => {
                dblist        => "${apachedir}/dblists/all-labs.dblist",
                closedlist    => "${apachedir}/dblists/closed-labs.dblist",
                flowlist      => "${apachedir}/dblists/flow_only_labs.dblist",
                skipdblist    => "${dblistsdir}/skip-labs.dblist",
                keep          => '2',
                chunksEnabled => '0',
                adminmail     => 'nomail',
                retryWait     => '30',
                maxRetries    => '3',
            },
            big => {
                dblist            => "${dblistsdir}/bigwikis-labs.dblist",
                closedlist        => "${apachedir}/dblists/closed-labs.dblist",
                flowlist          => "${apachedir}/dblists/flow_only_labs.dblist",
                skipdblist        => "${dblistsdir}/skipmonitor.dblist",
                keep              => '2',
                chunksEnabled     => '1',
                chunksForAbstract => '4',
                chunksForPagelogs => '4',
                checkpointTime    => '720',
                recombineHistory  => '0',
                revsPerJob        => '70000',
                revsMargin        => '20',
                fixeddumporder    => '1',
                lbzip2threads     => '2',
                wikis => {
                    enwiki => {
                        pagesPerChunkHistory  => '20000,40000,70000,80000',
                        pagesPerChunkAbstract => '4000',
                    },
                    simplewiki => {
                        pagesPerChunkHistory  => '20000,50000,90000,140000',
                        pagesPerChunkAbstract => '60000',
                    },
                    wikidatawiki => {
                        pagesPerChunkHistory  => '540000,30000,20000,30000',
                        pagesPerChunkAbstract => '25000',
                        lbzip2forhistory      => '1',
                    },
                },
            },
            en => {},
            wd => {},
            monitor => {},
            media => {},
        },
    }

    # for xml/sql dumps running on dumpsdata host
    # as well as misc dumps via various cron jobs
    snapshot::dumps::wikiconf { 'wikidump.conf.dumps':
        configtype => 'allwikis',
        config     => $config,
        publicdir  => $publicdir,
        privatedir => $privatedir,
        tempdir    => $tempdir,
    }

    # for xml/sql dumps testing in beta
    snapshot::dumps::wikiconf { 'wikidump.conf.labs':
        configtype => 'allwikis',
        config     => $labsconfig,
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
