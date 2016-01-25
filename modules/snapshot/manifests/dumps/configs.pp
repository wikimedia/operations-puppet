class snapshot::dumps::configs(
    $enable           = true,
    $hugewikis_enable = true,
) {

    include snapshot::dirs

    $config = {
        smallwikis => {
            dblist        => "${snapshot::dirs::apachedir}/dblists/all.dblist",
            skipdblist    => "${snapshot::dirs::dumpsdir}/dblists/skip.dblist",
            keep          => '12',
            chunksEnabled => '0',
        },
        bigwikis => {
            dblist           => "${snapshot::dirs::dumpsdir}/dblists/bigwikis.dblist",
            skipdblist       => "${snapshot::dirs::dumpsdir}/dblists/skipnone.dblist",
            keep             => '10',
            chunksEnabled    => '1',
            recombineHistory => '0',
            wikis            => {
                ruwiki => {
                    pagesPerChunkHistory  => '311181,1142420,1627923,3122803',
                    pagesPerChunkAbstract => '1200000',
                    chunksForAbstract     => '4',
                },
                eswiki => {
                    pagesPerChunkHistory  => '229078,854374,2324057,3860337',
                    pagesPerChunkAbstract => '1500000',
                    chunksForAbstract     => '4',
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
                },
                jawiki => {
                  pagesPerChunkHistory  => '168815,480631,943865,1760565',
                    pagesPerChunkAbstract => '800000',
                    chunksForAbstract     => '4',
                },
                commonswiki => {
                    pagesPerChunkHistory  => '6457504,9672260,12929298,17539944',
                    pagesPerChunkAbstract => '11000000',
                    chunksForAbstract     => '4',
                },
                wikidatawiki => {
                    pagesPerChunkHistory  => '2421529,4883997,8784997,8199134',
                    pagesPerChunkAbstract => '5800000',
                    chunksForAbstract     => '4',
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
            dblist           => "${snapshot::dirs::dumpsdir}/dblists/hugewikis.dblist",
            skipdblist       => "${snapshot::dirs::dumpsdir}/dblists/skipnone.dblist",
            keep             => '9',
            chunksEnabled    => '1',
            recombineHistory => '0',
            checkpointTime   => '720',
            wikis => {
                enwiki => {
                    pagesPerChunkHistory  => '30303,58141,112065,152180,212624,327599,375779,522388,545343,710090,880349,1113575,1157158,1547206,1773248,2021218,2153807,2427469,2634193,2467421, 2705827,2895677,3679790,3449365,4114387,4596259,6533612',
                    pagesPerChunkAbstract => '2000000',
                },
            },
        },
        monitor => {
            dblist        => "${snapshot::dirs::apachedir}/dblists/all.dblist",
            skipdblist    => "${snapshot::dirs::dumpsdir}/dblists/skipmonitor.dblist",
            keep          => '30',
            chunksEnabled => '0',
        },
    }

    if ($enable) {
        file { "${snapshot::dirs::dumpsdir}/confs":
            ensure => 'directory',
            path   => "${snapshot::dirs::dumpsdir}/confs",
            mode   => '0755',
            owner  => 'root',
            group  => 'root',
        }
        snapshot::dumps::wikiconf { 'wikidump.conf':
            configtype => 'smallwikis',
            config     => $config,
        }
        snapshot::dumps::wikiconf { 'wikidump.conf.bigwikis':
            configtype => 'bigwikis',
            config     => $config,
        }
        if ($hugewikis_enable) {
            snapshot::dumps::wikiconf { 'wikidump.conf.hugewikis':
                configtype => 'hugewikis',
                config     => $config,
            }
        }
        snapshot::dumps::wikiconf { 'wikidump.conf.monitor':
            configtype => 'monitor',
            config     => $config,
        }
    }
}
