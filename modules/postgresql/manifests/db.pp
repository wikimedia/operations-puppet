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
    if hiera('postgresql::db::enabled') {

      # Check if our db exists and store it
      $db_exists = "/usr/bin/psql --tuples-only --command 'SELECT datname FROM pg_catalog.pg_database;' | /bin/grep -q '^ ${name}'"

      if $ensure == 'present' {
          exec { "create_postgres_db_${name}":
              command => "/usr/bin/createdb --owner='${owner}' '${name}'",
              user    => 'postgres',
              unless  => $db_exists,
          }
      } else {
          exec { "drop_postgres_db_${name}":
              command => "/usr/bin/dropdb '${name}'",
              user    => 'postgres',
              onlyif  => $db_exists,
          }
      }

  } else {

      if $ensure == 'present' {
          exec { "prompt_to_manually_create_postgres_db_${name}":
              command => "/bin/echo 'postgresql::db is disabled, please create database \"${name}\" with owner \"${owner}\" manually' 1>&2 && false",
              unless  => $db_exists,
          }
      } else {
          exec { "prompt_to_manually_drop_postgres_db_${name}":
              command => "/bin/echo 'postgresql::db is disabled, please drop database \"${name}\" manually' 1>&2 && false",
              onlyif  => $db_exists,
          }
      }

  }
}
