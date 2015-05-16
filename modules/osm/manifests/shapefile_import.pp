#
# Definition: osm::shapefile_import
#
# This definition provides a way to load shapefiles from openstreetmapdata.com
# in a gis enabled db
# You must have downloaded and unzipped the zip file first and placed it in a
# configurable place
#
# Parameters:
#
# Actions:
#   load a previously downloaded shapefile
#
# Requires:
#   Class['postgresql::postgis']
#   define['postgresql::spatialdb']
#
# Sample Usage:
#  osm::shapefile_import {
#       database => 'gis',
#       input_shape_file => '/myshapefiledir',
#       shape_table => 'mytable',
#
define osm::shapefile_import(
    $database,
    $input_shape_file,
    $shape_table,
    ) {

    # Check if our db table exists
    $shapeline_exists = "/usr/bin/psql -d ${database} --tuples-only -c \'SELECT table_name FROM information_schema.tables;\' | /bin/grep \'${shape_table}\'"

    exec { "create_shapelines-${name}":
        command => "/usr/bin/shp2pgsql -D -I ${input_shape_file} ${shape_table} > /tmp/${shape_table}.dump",
        user    => 'postgres',
        unless  => $shapeline_exists,
    }
    exec { "load_shapefiles-${name}":
        command     => "/usr/bin/psql -d ${database} -f /tmp/${shape_table}.dump",
        user        => 'postgres',
        refreshonly => true,
        subscribe   => Exec["create_shapelines-${name}"],
    }
    exec { "delete_shapefiles-${name}":
        command     => "/bin/rm /tmp/${shape_table}.dump",
        user        => 'postgres',
        refreshonly => true,
        subscribe   => Exec["load_shapefiles-${name}"],
    }
}
