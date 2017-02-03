# wikistats host role class
# this is labs-only - wikistats.wmflabs.org (dzahn)
# NOT stats.wikimedia.org (analytics/ezachte)
# these projects are often confused
#
# filtertags: labs-project-wikistats
class role::wikistats::instance {

    system::role { 'wikistats': description => 'wikistats instance' }

    $wikistats_host = 'wikistats.wmflabs.org'

    class { '::wikistats':
        wikistats_host => $wikistats_host,
    }

}

