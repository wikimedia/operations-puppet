# == Define: sysfs::conffile
#
# Represents a file with sysfs kernel parameters in /etc/sysfs.d.
#
# === Parameters
#
# [*content*]
#   The content of the file provided as a string. Either this or
#   'source' must be specified.
#
# [*source*]
#   The content of the file provided as a puppet:/// file reference.
#   Either this or 'content' must be specified.
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
#  sysfs::conffile { 'hadoop':
#    content  => template('hadoop/hadoop.conf.erb'),
#    priority => 90,
#  }
#
define sysfs::conffile(
    $ensure   = present,
    $content  = undef,
    $source   = undef,
    $priority = 70
) {
    include ::sysfs

    if $priority !~ /^\d?\d$/ {
        fail("'priority' must be an integer between 0 - 99 (got: ${priority}).")
    }

    $basename = regsubst($title, '\W', '-', 'G')
    $filename = sprintf('/etc/sysfs.d/%02d-%s.conf', $priority, $basename)

    file { $filename:
        ensure  => $ensure,
        content => $content,
        source  => $source,
        notify  => Service['sysfsutils'],
    }
}
