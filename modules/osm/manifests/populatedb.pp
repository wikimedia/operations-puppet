#
# Definition: osm::populatedb
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
#  osm::populatedb { 'mydb': input_pbf_file => '/myfile.pbf' }
#
define osm::populatedb(
    $input_pbf_file,
    $input_shape_file,
    $shape_table,
    ) {

    # Check if our db tables exist
    $tables_exist = "/usr/bin/psql -d ${name} --tuples-only -c \'SELECT table_name FROM information_schema.tables;\' | /bin/grep \'planet_osm\'"
    $shapelines_exist = "/usr/bin/psql -d ${name} --tuples-only -c \'SELECT table_name FROM information_schema.tables;\' | /bin/grep \'${shape_table}\'"

    # Note. This is not needed anymore with osm2pgsql 0.81
    exec { "load_900913-${name}":
        command => "/usr/bin/psql -d ${name} -f /usr/share/osm2pgsql/osm2pgsql/900913.sql",
        user    => 'postgres',
        unless  => $tables_exist,
    }

    $load_planet_cmd = inline_template("<%- data=@memoryfree.split(' '); multi={'MB' => 1, 'GB' => 1000}[data[1]]-%>/usr/bin/osm2pgsql -s -C <%= data[0].to_i*multi %> -d <%= @name %> --number-processes <%= @processorcount %> <%= @input_pbf_file %>")
    exec { "load_planet_osm-${name}":
        command     => $load_planet_cmd,
        user        => 'postgres',
        refreshonly => true,
        subscribe   => Exec["load_900913-${name}"],
    }

    exec { "create_shapelines-${name}":
        command     => "/usr/bin/shp2pgsql -D -I ${input_shape_file} ${shape_table} > /tmp/${shape_table}.dump",
        user        => 'postgres',
        unless      => $shapelines_exist,
    }
    exec { "load_shapefiles-${name}":
        command     => "/usr/bin/psql -d ${name} -f /tmp/${shape_table}.dump",
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
