#
# Definition: postgresql::spatialdb
#
# This definition provides a way to manage spatial dbs
#
# Parameters:
#
# Actions:
#   Create/drop database
#
# Requires:
#   Class['postgresql::postgis']
#
# Sample Usage:
#  postgresql::spatialdb { 'mydb': }
#
define postgresql::spatialdb(
     $ensure = 'present'
     ) {

    # Check if our db exists and store it
    $dbexists = "/usr/bin/psql --tuples-only -c \'SELECT datname FROM pg_catalog.pg_database;\' | /bin/grep \'^ ${name}\'"
    # Check if plgsql is installed
    $plpgsqlexists = "/usr/bin/psql --tuples-only -c \'SELECT lanname FROM pg_catalog.pg_language;\' | /bin/grep \'^ plpgsql\'"
    # Check if postgis is installed
    $postgisexists = "/usr/bin/psql --tuples-only -c \"SELECT table_catalog FROM information_schema.tables where table_name=\'geometry_columns\';\" ${name} | /bin/grep \'^ ${name}\'"

    if $ensure == 'present' {
        exec { "create_db-${name}":
            command => "/usr/bin/createdb ${name}",
            user    => "postgres",
            unless  => $dbexists,
        }
        exec { "create_plpgsql_lang-${name}":
            command => "/usr/bin/createlang plpgsql ${name}",
            user    => "postgres",
            unless  => $plpgsqlexists,
        }
        exec { "create_postgis-${name}":
            command => "/usr/bin/psql -d ${name} -f /usr/share/postgresql/9.1/contrib/postgis-1.5/postgis.sql",
            user    => "postgres",
            unless  => $postgisexists,
        }

        Exec["create_db-${name}"] -> Exec["create_plpgsql_lang-${name}"]
        Exec["create_plpgsql_lang-${name}"] -> Exec["create_postgis-${name}"]
    } elsif $ensure == 'absent' {
        exec { "drop_db-${name}":
            command => "/usr/bin/dropdb ${name}",
            user    => "postgres",
            onlyif  => $dbexists,
        }
        exec { "drop_plpgsql_lang-${name}":
            command => "/usr/bin/droplang plpgsql ${name}",
            user    => "postgres",
            onlyif  => $plpgsqlexists,
        }
        Exec["drop_plpgsql_lang-${name}"] -> Exec["drop_db-${name}"]
    }
}
