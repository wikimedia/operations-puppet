#
# Definition: postgresql::db
#
# Manages a PostgreSQL database.
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
# [*pgversion*]
#   PostgreSQL version, e.g. '9.4'. Doesn't really do anything. 
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
    $ensure = 'present',
    $name = $title,
    $owner = 'postgres',
    $pgversion = '9.1',
) {

    # Check if our db exists and store it
    $db_exists = "/usr/bin/psql --tuples-only -c \'SELECT datname FROM pg_catalog.pg_database;\' | /bin/grep \'^ ${name}\'"

    if $ensure == 'present' {
        exec { "createdb-${name}":
            command => "/usr/bin/createdb --owner=${owner} ${name}",
            user    => 'postgres',
            unless  => $db_exists,
        }
    } elsif $ensure == 'absent' {
        exec { "dropdb-${name}":
            command => "/usr/bin/dropdb ${name}",
            user    => "postgres",
            onlyif  => $db_exists,
        }
    }
}
