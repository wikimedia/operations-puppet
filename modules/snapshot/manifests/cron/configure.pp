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
            shards   => 8,
            fileSize_json => 20000000000,
            fileSize_all => 23500000000,
            fileSize_truthy => 14000000000,
            fileSize_lexemes => 1000,
        },
    }
    $config_labs = {
        global => {
            dblist => "${apachedir}/dblists/all-labs.dblist",
        },
        wikidata => {
            shards   => 2,
            fileSize_json => 2000,
            fileSize_all => 2000,
            fileSize_truthy => 2000,
            fileSize_lexemes => 100,
        },
    }
    snapshot::cron::configfile{ 'wikidump.conf.other':
        configvals => $config,
    }
    snapshot::cron::configfile{ 'wikidump.conf.other.labs':
        configvals => $config_labs,
    }
}