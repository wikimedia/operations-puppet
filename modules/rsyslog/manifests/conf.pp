# == Define: rsyslog::conf
#
# Represents an rsyslogd config file. See rsyslog.conf(5).
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
#   A numeric value in range 0 - 99. Files with a lower priority value
#   are evaluated first.
#
#   If you're not sure, leave this unspecified. The default value of 60
#   should suit most cases.
#
# === Examples
#
#  rsyslog::conf { 'hadoop':
#    content  => template('hadoop/hadoop.conf.erb'),
#    priority => 90,
#  }
#
define rsyslog::conf(
    $ensure   = present,
    $content  = undef,
    $source   = undef,
    $priority = 60
) {
    include ::rsyslog

    if $priority !~ /^\d?\d$/ {
        fail("'priority' must be an integer between 0 - 99 (got: ${priority}).")
    }

    $basename = regsubst($title, '[\W_]', '-', 'G')
    $filename = sprintf('/etc/rsyslog.d/%02d-%s.conf', $priority, $basename)

    file { $filename:
        ensure  => $ensure,
        content => ensure_final_newline($content),
        source  => $source,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['rsyslog'],
    }
}
