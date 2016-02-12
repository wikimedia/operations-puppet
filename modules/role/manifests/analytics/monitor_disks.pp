# == Class role::analytics::hadoop::monitor_disks
# Installs monitoring plugins for disks
#
class role::analytics::monitor_disks {
    if $::standard::has_ganglia {
        ganglia::plugin::python { 'diskstat': }
    }
}
