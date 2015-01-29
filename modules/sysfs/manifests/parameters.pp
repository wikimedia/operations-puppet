# == Define: sysfs::parameters
#
# This custom resource lets you specify sysfs parameters using a Puppet
# hash, set as the 'values' parameter.
#
# === Parameters
#
# [*values*]
#   A hash that maps kernel parameter names to their desire value.
#
# [*priority*]
#   A numeric value in range 60 - 99. In case of conflict, files with a
#   higher priority override files with a lower priority.
#
#   If you're not sure, leave this unspecified. The default value of 60
#   should suit most cases.
#
# === Examples
#
#  sysfs::parameters { 'sda_deadline':
#    values => {
#      'block.sda.queue.scheduler' => 'deadline',
#    },
#    priority => 90,
#  }
#
define sysfs::parameters(
    $values,
    $ensure   = present,
    $priority = 70
) {
    sysfs::conffile { $title:
        ensure   => $ensure,
        content  => template('sysfs/sysfs.conf.erb'),
        priority => $priority,
    }
}
