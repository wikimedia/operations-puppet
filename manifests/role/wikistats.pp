# wikistats host role class
# this is labs only! - wikistats.wmflabs.org (dzahn)
# NOT stats.wikimedia.org (analytics/ezachte)
# realm case is just here for compatibility
class role::wikistats {

    system::role { 'wikistats': description => 'wikistats instance' }

    # config - labs vs. production
    case $::realm {
        'labs': {
            $wikistats_host = 'wikistats.wmflabs.org'
        }
        'production': {
            $wikistats_host = 'wikistats.wikimedia.org'
        }
        default: {
            fail('unknown realm, should be labs or production')
        }
    }

    # main, ::wikistats refers to the module class in init.pp
    class { '::wikistats':
        wikistats_host => $wikistats_host,
    }

}

