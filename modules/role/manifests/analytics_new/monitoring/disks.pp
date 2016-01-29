# == Class role::analytics_new::monitoring::disks
# Installs ganglia monitoring plugins for disks
#
class role::analytics_new::monitoring::disks {
    if $::standard::has_ganglia {
        ganglia::plugin::python { 'diskstat': }
    }
}
