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
                    pagesPerChunkHistory  => '256900,895900,1280900,2000000',
                    pagesPerChunkAbstract => '1200000',
                    chunksForAbstract     => '4',
                },
                eswiki => {
                    pagesPerChunkHistory  => '190300,671500,1627200,2000000',
                    pagesPerChunkAbstract => '1500000',
                    chunksForAbstract     => '4',
                },
                dewiki => {
                    pagesPerChunkHistory  => '33640,1446760,2569200,3000000',
                    pagesPerChunkAbstract => '2000000',
                    chunksForAbstract     => '4',
                    checkpointTime        => '720',
                },
                ptwiki => {
                    pagesPerChunkHistory  => '137500,668700,1208900,2000000',
                    pagesPerChunkAbstract => '1000000',
                    chunksForAbstract     => '4',
                },
                plwiki => {
                    pagesPerChunkHistory  => '208000,422000,818900,2000000',
                    pagesPerChunkAbstract => '800000',
                    chunksForAbstract     => '4',
                },
                nlwiki => {
                    pagesPerChunkHistory  => '200800,490800,934600,2000000',
                    pagesPerChunkAbstract => '1000000',
                    chunksForAbstract     => '4',
                },
                frwiki => {
                    pagesPerChunkHistory  => '348700,965200,2331100,3000000',
                    pagesPerChunkAbstract => '1900000',
                    chunksForAbstract     => '4',
                    checkpointTime        => '720',
                },
                itwiki => {
                    pagesPerChunkHistory  => '335400,941600,1180900,2000000',
                    pagesPerChunkAbstract => '1200000',
                    chunksForAbstract     => '4',
                },
                jawiki => {
                    pagesPerChunkHistory  => '149600,801600,408900,2000000',
                    pagesPerChunkAbstract => '800000',
                    chunksForAbstract     => '4',
                },
                commonswiki => {
                    pagesPerChunkHistory  => '6440000,8960000,11260000,20000000',
                    pagesPerChunkAbstract => '11000000',
                    chunksForAbstract     => '4',
                },
                wikidatawiki => {
                    pagesPerChunkHistory  => '2300000,4500000,8600000,10000000',
                    pagesPerChunkAbstract => '5800000',
                    chunksForAbstract     => '4',
                },
                zhwiki => {
                    pagesPerChunkHistory  => '280000,740000,2100000,3000000',
                    pagesPerChunkAbstract => '1300000',
                    chunksForAbstract     => '4',
                },
                metawiki => {
                    pagesPerChunkHistory  => '810000,2700000,3200000,3400000',
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
                    pagesPerChunkHistory  => '10000,15000,30000,50000,80000,120000,160000,200000,260000,400000,500000,600000,700000,800000,900000,1200000,1500000,1700000,1900000,2200000,2400000,2500000,2700000,2800000,2900000,3000000,3000000',
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
