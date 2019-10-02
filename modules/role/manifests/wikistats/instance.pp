# wikistats host role class
# this is labs-only - https://wikistats.wmflabs.org (dzahn)
# NOT stats.wikimedia.org (analytics)
# these projects are often confused
#
# filtertags: labs-project-wikistats
class role::wikistats::instance {

    system::role { 'wikistats': description => 'wikistats instance' }

    require ::profile::wikistats
    require ::profile::wikistats::db
    require ::profile::wikistats::httpd
}
