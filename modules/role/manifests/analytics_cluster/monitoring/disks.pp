# == Class role::analytics_cluster::monitoring::disks
# Installs ganglia monitoring plugins for disks
#
class role::analytics_cluster::monitoring::disks {
    if $::standard::has_ganglia {
        ganglia::plugin::python { 'diskstat': }
    }
}
