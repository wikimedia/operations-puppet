# this is labs-only - wikistats.wmflabs.org (dzahn)
# NOT stats.wikimedia.org (analytics)
# these projects are often confused
#
class profile::wikistats {

    class { '::wikistats':
        wikistats_host => $::fqdn,
    }

}
