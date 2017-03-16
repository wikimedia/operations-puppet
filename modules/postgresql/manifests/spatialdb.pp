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
    $ensure = 'present',
    $pgversion = hiera('postgresql::spatialdb::pgversion', '9.1'),
    $postgis_version = hiera('postgresql::spatialdb::postgis_version', '1.5'),
    ) {

    require ::postgresql::packages
    require ::postgresql::postgis

    # Check if our db exists and store it
    $db_exists = "/usr/bin/psql --tuples-only -c \'SELECT datname FROM pg_catalog.pg_database;\' | /bin/grep \'^ ${name}\'"
    # Check if plgsql is installed
    $plpgsql_exists = "/usr/bin/psql --tuples-only -c \'SELECT lanname FROM pg_catalog.pg_language;\' | /bin/grep \'^ plpgsql\'"
    # Check if postgis is installed
    $postgis_exists_sql = 'SELECT table_catalog FROM information_schema.tables where \table_name=\'geometry_columns\';'
    $postgis_exists = "/usr/bin/psql --tuples-only -c \"${postgis_exists_sql}\" ${name} | /bin/grep \'^ ${name}\'"

    $postgres_basedir = "/usr/share/postgresql/${pgversion}"

    if $ensure == 'present' {
        exec { "create_db-${name}":
            command => "/usr/bin/createdb ${name}",
            user    => 'postgres',
            unless  => $db_exists,
        }
        if $postgis_version == '1.5' {
            exec { "create_plpgsql_lang-${name}":
                command => "/usr/bin/createlang plpgsql ${name}",
                user    => 'postgres',
                unless  => $plpgsql_exists,
            }
            exec { "create_postgis-${name}":
                command => "/usr/bin/psql -d ${name} -f ${postgres_basedir}/contrib/postgis-${postgis_version}/postgis.sql",
                user    => 'postgres',
                unless  => $postgis_exists,
            }
            # Create spatial_ref_sys
            exec { "create_spatial_ref_sys-${name}":
                command     => "/usr/bin/psql -d ${name} -f ${postgres_basedir}/contrib/postgis-${postgis_version}/spatial_ref_sys.sql",
                user        => 'postgres',
                refreshonly => true,
                subscribe   => Exec["create_postgis-${name}"],
            }
            exec { "grant_ref_sys_cmd-${name}":
                command     => "/usr/bin/psql -d ${name} -c \"GRANT SELECT ON spatial_ref_sys TO PUBLIC;\"",
                user        => 'postgres',
                refreshonly => true,
                subscribe   => Exec["create_spatial_ref_sys-${name}"],
            }
            exec { "create_comments-${name}":
                command     => "/usr/bin/psql -d ${name} -f ${postgres_basedir}/contrib/postgis_comments.sql",
                user        => 'postgres',
                refreshonly => true,
                subscribe   => Exec["create_spatial_ref_sys-${name}"],
            }
            # Create comments
            exec { "grant_comments_cmd-${name}":
                command     => "/usr/bin/psql -d ${name} -c \"GRANT ALL ON geometry_columns TO PUBLIC;\"",
                user        => 'postgres',
                refreshonly => true,
                subscribe   => Exec["create_comments-${name}"],
            }
        } else {
            exec { "create_postgis-${name}":
                command     => "/usr/bin/psql -d ${name} -c \"CREATE EXTENSION postgis;\"",
                user        => 'postgres',
                refreshonly => true,
                subscribe   => Exec["create_db-${name}"],
            }
        }
        exec { "create_extension_hstore-${name}":
            command     => "/usr/bin/psql -d ${name} -c \"CREATE EXTENSION hstore;\"",
            user        => 'postgres',
            refreshonly => true,
            subscribe   => Exec["create_db-${name}"],
        }
    } elsif $ensure == 'absent' {
        exec { "drop_db-${name}":
            command => "/usr/bin/dropdb ${name}",
            user    => 'postgres',
            onlyif  => $db_exists,
        }
        exec { "drop_plpgsql_lang-${name}":
            command => "/usr/bin/droplang plpgsql ${name}",
            user    => 'postgres',
            onlyif  => $plpgsql_exists,
        }
        Exec["drop_plpgsql_lang-${name}"] -> Exec["drop_db-${name}"]
    }
}
