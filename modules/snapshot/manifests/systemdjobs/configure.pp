class snapshot::systemdjobs::configure(
    $php = undef,
) {
    $dblist = "${snapshot::dumps::dirs::apachedir}/dblists/all.dblist"
    $tempdir = $snapshot::dumps::dirs::dumpstempdir
    $apachedir = $snapshot::dumps::dirs::apachedir
    $confsdir = $snapshot::dumps::dirs::confsdir
    $config = {
        global => {
            dblist => "${apachedir}/dblists/all.dblist",
        },
        wikidata => {
            # settings for wikidata entity dumps
            shards   => 8,
            # when updating these size santy checks, look at current production (gzip)
            # ttl/ json dump filesizes, since those are smallest, or ttl rdf if no json
            # dump is produced (i.e. for "truthy").
            fileSizes => 'all:90000000000,truthy:50000000000,lexemes:200000000',
            # chosen so that each batch will finish in well under 1h
            pagesPerBatch => 65000,
        },
        commons => {
            # settings for commons entity dumps
            shards   => 8,
            # when updating these size sanity checks, look at current production (gzip)
            # json filesizes, since those are smallest.
            fileSizes => 'mediainfo:1600000000',
            # chosen so that each batch will finish in well under 1h
            pagesPerBatch => 100000,
        },
    }
    $config_labs = {
        global => {
            dblist => "${apachedir}/dblists/all-labs.dblist",
        },
        wikidata => {
            shards   => 2,
            fileSizes => 'all:10000000,truthy:30000000,lexemes:600000',
            pagesPerBatch => 20000,
        },
        commons => {
            shards   => 2,
            fileSizes => 'mediainfo:500000',
            pagesPerBatch => 20000,
        },
    }
    snapshot::systemdjobs::configfile{ 'wikidump.conf.other':
        configvals => $config,
    }
    snapshot::systemdjobs::configfile{ 'wikidump.conf.other.labs':
        configvals => $config_labs,
    }
}
