class snapshot::cron::configure(
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
            # when updating these size santy checks, look at current production sizes of
            # ttl json filesizes, since those are smallest, or ttl rdf if no json
            # dump is produced (i.e. for "truthy").
            fileSizes => 'all:90000000000,truthy:40000000000,lexemes:150000000',
            pagesPerBatch => 200000,
        },
        commons => {
            # settings for commons entity dumps
            shards   => 8,
            # when updating these size sanity checks, look at current production sizes of
            # ttl json filesizes, since those are smallest
            fileSizes => 'mediainfo:15000000000',
            pagesPerBatch => 200000,
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
            fileSize => 'mediainfo:1000000',
            pagesPerBatch => 20000,
        },
    }
    snapshot::cron::configfile{ 'wikidump.conf.other':
        configvals => $config,
    }
    snapshot::cron::configfile{ 'wikidump.conf.other.labs':
        configvals => $config_labs,
    }
}