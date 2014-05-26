# == Define: rsyslog::rotated_log
#
# A convenience resource for configuring log rotation for a log file
# that is written to by rsyslog. The defaults match the configuration of
# other rotated rsyslog files, as defined in /etc/logrotate.d/rsyslog.
# If you need something more specific, provision your own.
#
# === Parameters
#
# [*path*]
#   Path of log file to rotate. Defaults to the resource title.
#
# [*period*]
#   How often log files are rotated: 'daily', 'weekly', or 'monthly'.
#   Defaults to 'weekly'.
#
# [*rotate*]
#   Number of times logs should be rotated before they are removed.
#   If set to zero, old versions are removed rather than rotated.
#
# === Examples
#
#  rsyslog::rotated_log { '/var/log/ganglia.log':
#    period => 'daily',
#    rotate => 0,
#  }
#
define rsyslog::rotated_log(
    $ensure = present,
    $path   = $title,
    $period = 'weekly',
    $rotate = 4,
) {
    include ::rsyslog

    if $period !~ /^(daily|weekly|monthly)$/ {
        fail("'period' must be 'daily', 'weekly', or 'monthly' (got: '${period}')")
    }

    $basename = inline_template('<%= File.basename @path, ".log" %>')

    file { "/etc/logrotate.d/rsyslog-${basename}":
        ensure  => $ensure,
        content => template('rsyslog/logrotate.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        before  => Service['rsyslog'],
    }
}
