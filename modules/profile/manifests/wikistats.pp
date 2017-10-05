# this is labs-only - wikistats.wmflabs.org (dzahn)
# NOT stats.wikimedia.org (analytics)
# these projects are often confused
#
class profile::wikistats (
    $wikistats_host = hiera('profile::wikistats::wikistats_host'),
) {

    class { '::wikistats':
        wikistats_host => $wikistats_host,
    }
}
