#
# Definition: osm::usergrants
#
# This definition provides a way to add the needed rights to spatial dbs
#
# Parameters:
#
# Actions:
#   Grant/revoke rights
#
# Requires:
#   Class['postgresql::postgis']
#   define['postgresql::spatialdb']
#
# Sample Usage:
#  osm::usergrants { 'mydb': postgresql_user => 'myser' }
#
define osm::usergrants(
    $postgresql_user,
    $ensure = 'present',
    ) {

    # Check if our db exists and store it
    $db_exists = "/usr/bin/psql --tuples-only -c \'SELECT datname FROM pg_catalog.pg_database;\' | /bin/grep \'^ ${name}\'"


    if $ensure == 'present' {
        exec { "grant_osm_rights-${name}":
            command => "/usr/bin/psql -d ${name} -c \"GRANT SELECT ON geometry_columns, spatial_ref_sys, planet_osm_line, planet_osm_nodes, planet_osm_point, planet_osm_rels, planet_osm_roads, planet_osm_ways, planet_osm_polygon TO ${postgresql_user};\"",
            user    => 'postgres',
            onlyif  => $db_exists,
        }
    } elsif $ensure == 'absent' {
        exec { "revoke_osm_rights-${name}":
            command => "/usr/bin/psql -d ${name} -c \"GRANT SELECT ON geometry_columns, spatial_ref_sys, planet_osm_line, planet_osm_nodes, planet_osm_point, planet_osm_rels, planet_osm_roads, planet_osm_ways, planet_osm_polygon FROM ${postgresql_user};\"",
            user    => 'postgres',
            onlyif  => $db_exists,
        }
    }
}
