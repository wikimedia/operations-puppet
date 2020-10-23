class snapshot::dumps::configs(
    $php = undef,
) {
    $dblistsdir = $snapshot::dumps::dirs::dblistsdir
    $apachedir = $snapshot::dumps::dirs::apachedir
    $confsdir = $snapshot::dumps::dirs::confsdir
    $publicdir = $snapshot::dumps::dirs::xmldumpspublicdir
    $privatedir = $snapshot::dumps::dirs::xmldumpsprivatedir
    $tempdir = $snapshot::dumps::dirs::dumpstempdir

    $enchunkhistory1 = '41242,110331,159756,247062,399654,525616,650450,802149,1109142,1353964,1655493,2117929,2486894,2664920'
    $enchunkhistory2 = '3135550,3110240,3145805,3405653,4186592,4213990,4473813,4792696,5775612,6461102,5560195,1390059,1390050'

    $wikidatachunkhistory1 = '441397,673534,934710,1048805,1370558,1583567,1785525,3657704,2502567,2238612,1433305,2212873,2952969,2188014'
    $wikidatachunkhistory2 = '2042315,2511750,2132671,4342391,4169528,5304245,5163445,5039547,4462666,5392560,10213635,12386980,9233733'

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
                revinfostash      => '1',
                wikis => {
                    ruwiki => {
                        pagesPerChunkHistory  => '224167,817876,1156226,1637503,2749993,1916957',
                    },
                    eswiki => {
                        pagesPerChunkHistory  => '159400,533923,1204417,2669088,2728044,2302201',
                    },
                    dewiki => {
                        pagesPerChunkHistory  => '297012,965081,2114164,2739207,3145780,2203157',
                    },
                    ptwiki => {
                        pagesPerChunkHistory  => '105695,408017,1115512,1251580,2144104,1354362',
                    },
                    plwiki => {
                        pagesPerChunkHistory  => '187037,377742,634739,848374,1414501,1441349',
                    },
                    nlwiki => {
                        pagesPerChunkHistory  => '134538,349514,607986,977232,1838650,1517358',
                    },
                    frwiki => {
                        pagesPerChunkHistory  => '306134,744688,1926392,2224859,3872210,4517475',
                    },
                    itwiki => {
                        pagesPerChunkHistory  => '316052,888921,1001801,1386562,2322043,2735363',
                    },
                    jawiki => {
                        pagesPerChunkHistory  => '114794,275634,511979,819239,1086301,1409298',
                    },
                    commonswiki => {
                        pagesPerChunkHistory  => '10087570,13102946,15429735,17544212,19379466,18705774',
                    },
                    zhwiki => {
                        pagesPerChunkHistory  => '187712,442448,759488,2001381,2205350,1611528',
                    },
                    metawiki => {
                        pagesPerChunkHistory  => '368138,1935662,2660817,2746757,2479647,930497',
                    },
                    hewiki => {
                        pagesPerChunkHistory  => '68044,178941,340885,409429,488119,397741',
                    },
                    huwiki => {
                        pagesPerChunkHistory  => '62918,155323,226242,335367,479183,466541',
                    },
                    arwiki => {
                        pagesPerChunkHistory  => '340838,864900,1276577,1562792,2015625,1772989',
                    },
                    svwiki => {
                        pagesPerChunkHistory  => '153415,513562,1023792,2103602,2525365,2166272',
                    },
                    ukwiki => {
                        pagesPerChunkHistory  => '194007,343475,450503,686457,897404,1424811',
                    },
                    viwiki => {
                        pagesPerChunkHistory  => '832082,1120003,2613161,3614798,4263484,7050789',
                    },
                    kowiki => {
                        pagesPerChunkHistory  => '82407,171387,296569,433131,786946,1079962',
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
                revinfostash      => '1',
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
                emptyAbstracts       => '1',
                revinfostash      => '1',
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
                        revinfostash          => '1',
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
