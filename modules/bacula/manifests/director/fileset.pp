# Definition: bacula::director::fileset
#
# Create a fileset definition to the director
#
# Parameters:
#   $includes
#       An array of files, dirs to be included in backups.
#   $excludes
#       An array of files, dirs to be excluded from backups.
#
# Actions:
#       Will create a fileset definition to be used by the director
#
# Requires:
#       bacula::director
#
# Sample Usage:
#       bacula::director::fileset { 'root-var'
#           includes     => [ '/', '/var',],
#           excludes     => [ '/tmp', ],
#       }
#
define bacula::director::fileset($includes, $excludes=undef) {
    file { "/etc/bacula/conf.d/fileset-${name}.conf":
        ensure  => present,
        owner   => root,
        group   => bacula,
        mode    => '0440',
        content => template('bacula/bacula-dir-fileset.erb'),
        notify  => Service['bacula-director'],
    }
}
