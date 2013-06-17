# Definition: bacula::director::catalog
#
# This definition creates a catalog definition
#
# Parameters:
#   $runs
#       An array of hashes for 
#
# Actions:
#       Will create a catalog definition to be included by the director
#
# Requires:
#       bacula::director
#
# Sample Usage:
#       bacula::director::catalog { 'Tue':
#           runs     => [
#                        { level => 'Full', at => '1st Sat at 00:00'},
#                        { level => 'Differential', at => '3rd Sat at 00:00'},
#       }

define bacula::director::catalog($dbname, $dbuser, $dbhost, $dbport, $dbpassword) {

    file { "/etc/bacula/conf.d/catalog-${name}.conf":
        ensure  => present,
        owner   => root,
        group   => bacula,
        mode    => '0640',
        content => template('bacula/bacula-dir-catalog.erb'),
        notify  => Service['bacula-director'],
    }
}
