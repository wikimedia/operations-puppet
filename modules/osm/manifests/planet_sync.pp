#
# Definition: osm::planet_sync
#
# This definition provides a way to sync planet_osm in a gis enabled db
#
# Parameters:
#
# Actions:
#   sync with planet.osm
#
# Requires:
#   Class['postgresql::postgis']
#   define['postgresql::spatialdb']
#
# Sample Usage:
#  osm::planet_sync { 'mydb': }
#
define osm::planet_sync(
                $osmosis_dir='/srv/osmosis',
                $period='minute',
                $hour='*',
                $minute='*/30'
) {

    file { $osmosis_dir:
        ensure => directory,
        owner  => 'postgres',
        group  => 'postgres',
        mode   => 0700,
    }

    file { "${osmosis_dir}/configuration.txt":
        ensure  => present,
        owner   => 'postgres',
        group   => 'postgres',
        mode    => 0400,
        content => template('osm/osmosis_configuration.txt.erb'),
    }

    $sync_planet_cmd = inline_template("<%- data=@memoryfree.split(' '); multi={'MB' => 1, 'GB' => 1000}[data[1]]-%>/usr/bin/osmosis --read-replication-interval workingDirectory=<%= @osmosis_dir %> --simplify-change --write-xml-change - | /usr/bin/osm2pgsql -s -C <%= data[0].to_i*multi %> --number-processes <%= @processorcount %> --append -")
    cron { "planet_sync-${name}":
        environment => "JAVACMD_OPTIONS='-Dhttp.proxyHost=webproxy.eqiad.wmnet -Dhttp.proxyPort=8080'",
        command => $sync_planet_cmd,
        user    => 'postgres',
        hour    => $hour,
        minute  => $minute,
    }
}
