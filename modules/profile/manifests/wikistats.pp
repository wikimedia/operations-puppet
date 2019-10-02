# this is labs-only - wikistats.wmflabs.org (dzahn)
# NOT stats.wikimedia.org (analytics)
# these projects are often confused
#
class profile::wikistats {

    motd::script { 'deployment_info':
        ensure   => 'present',
        priority => 1,
        content  => template('wikistats/deployment_info.motd.erb'),
    }

    class { '::wikistats':
        wikistats_host => $::fqdn,
    }
}
