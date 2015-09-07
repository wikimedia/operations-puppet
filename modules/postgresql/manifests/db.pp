#
# Definition: postgresql::db
#
# Manages a PostgreSQL database.
#
# Does not do anything unless the postgresql::db::enabled
# hiera key is true (this is used to disallow automated
# DB creation in production).
#
# Parameters:
#
# [*ensure*]
#   'present' to create the database, 'absent' to delete it
#
# [*name*]
#   Database name (falls back to the resource title).
#
# [*owner*]
#   User who will own the database (defaults to 'postgres')
#
# Actions:
#   Create/drop database
#
# Requires:
#   Class['postgresql::server']
#
# Sample Usage:
#  postgresql::db { 'mydb': }
#
define postgresql::db(
    $ensure = present,
    $name   = $title,
    $owner  = 'postgres',
) {
    if $ensure == 'present' {
        exec { "create_postgres_db_${name}":
            command => "/usr/bin/createdb --owner='${owner}' '${name}'",
            user    => 'postgres',
            unless  => "/usr/local/sbin/postgres_db_exists '${name}'",
        }
    } elsif $ensure == 'absent' {
        exec { "drop_postgres_db_${name}":
            command => "/usr/bin/dropdb '${name}'",
            user    => 'postgres',
            onlyif  => "/usr/local/sbin/postgres_db_exists '${name}'",
        }
    } else {
        fail("'ensure' must be 'present' or 'absent'")
    }
}
