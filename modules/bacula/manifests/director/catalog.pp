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
#       bacula::director::catalog { 'MYDB':
#           dbname      => 'bacula',
#           dbuser      => 'bacula',
#           dbhost      => 'bacula-db.example.org',
#           dbport      => '3306',
#           dbpassword  => 'bacula',
#       }
#
define bacula::director::catalog($dbname, $dbuser, $dbhost, $dbport, $dbpassword) {
    file { "/etc/bacula/conf.d/catalog-${name}.conf":
        ensure  => present,
        owner   => root,
        group   => bacula,
        mode    => '0440',
        content => template('bacula/bacula-dir-catalog.erb'),
        notify  => Service['bacula-director'],
    }
}
