#
# Definition: osm::planet_import
#
# This definition provides a way to load planet_osm in a gis enabled db
# You must have downloaded the pbf first and placed it in a configurable place
#
# Parameters:
#
# Actions:
#   load a planet.osm
#
# Requires:
#   Class['postgresql::postgis']
#   define['postgresql::spatialdb']
#
# Sample Usage:
#  osm::planet_import { 'mydb': input_pbf_file => '/myfile.pbf' }
#
define osm::planet_import(
    $input_pbf_file,
    ) {

    # Check if our db tables exist
    $tables_exist="/usr/bin/psql -d ${name} --tuples-only -c \'SELECT table_name FROM information_schema.tables;\'|/bin/grep \'planet_osm\'"

    # Note. This is not needed anymore with osm2pgsql 0.81
    if os_version('ubuntu <= precise') {
        exec { "load_900913-${name}":
            command => "/usr/bin/psql -d ${name} -f /usr/share/osm2pgsql/osm2pgsql/900913.sql",
            user    => 'postgres',
            unless  => $tables_exist,
        }
    }
}
