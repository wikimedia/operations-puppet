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
    $owner  = 'postgres',
) {
    validate_ensure($ensure)

    $name_safe = regsubst($name, '[\W_]', '_', 'G')

    if $ensure == 'present' {
        exec { "create_postgres_db_${name_safe}":
            command => "/usr/bin/createdb --owner='${owner}' '${name}'",
            unless  => "/usr/bin/pg_dump --schema-only --dbname='${name}'",
            user    => 'postgres',
        }
    } else {
        exec { "drop_postgres_db_${name_safe}":
            command => "/usr/bin/dropdb '${name}'",
            onlyif  => "/usr/bin/pg_dump --schema-only --dbname='${name}'",
            user    => 'postgres',
        }
    }
}
