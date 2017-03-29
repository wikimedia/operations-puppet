define postgresql::db::extension (
    $extname,
    $database,
    $ensure = present,
) {

    $db_sql = "SELECT datname from pg_catalog.pg_database where datname = '${database}'"
    $db_exists = "/usr/bin/test -n \"\$( /usr/bin/psql -At -c \"${db_sql}\")\""

    $extension_sql = "SELECT extname FROM pg_extension WHERE extname = '${extname}'"
    $extension_exists = "/usr/bin/test -n \"\$( /usr/bin/psql -At -d ${database} -c \"${extension_sql}\")\""

    case $ensure {
        absent: {
            exec { "drop_extension_${extname}_on_${database}":
                command => "/usr/bin/psql -d ${database} -c \"DROP EXTENSION ${extname};\"",
                user    => 'postgres',
                onlyif  => "${db_exists} && ${extension_exists}",
            }
        }
        default: {
            exec { "create_extension_${extname}_on_${database}":
                command => "/usr/bin/psql -d ${database} -c \"CREATE EXTENSION ${extname};\"",
                user    => 'postgres',
                unless  => "${db_exists} && ${extension_exists}",
            }
        }
    }
}