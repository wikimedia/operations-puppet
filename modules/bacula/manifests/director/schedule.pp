# Definition: bacula::director::schedule
#
# This definition creates a schedule definition
#
# Parameters:
#   $runs
#       An array of hashes for configuring levels and runtimes
#
# Actions:
#       Will create a schedule definition to be included by the director
#
# Requires:
#       bacula::director
#
# Sample Usage:
#       bacula::director::schedule { 'Tue':
#           runs     => [
#                        { level => 'Full', at => '1st Sat at 00:00'},
#                        { level => 'Differential', at => '3rd Sat at 00:00'},
#       }
#
define bacula::director::schedule($runs) {
    file { "/etc/bacula/conf.d/schedule-${name}.conf":
        ensure  => present,
        owner   => root,
        group   => bacula,
        mode    => '0440',
        content => template('bacula/bacula-dir-schedule.erb'),
        notify  => Service['bacula-director'],
    }
}
