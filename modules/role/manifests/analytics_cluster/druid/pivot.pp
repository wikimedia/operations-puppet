# == Class role::analytics_cluster::druid::pivot
# Imply's Pivot nodejs UI to explore Druid data
#
class role::analytics_cluster::druid::pivot {
    class {'::pivot':
        druid_broker => 'druid1001.eqiad.wmnet',
    }
}