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
define osm::planet_sync(
                $osmosis_dir='/srv/osmosis',
                $expire_dir='/srv/osm_expire',
                $period='minute',
                $hour='*',
                $minute='*/30'
) {

    file { $expire_dir:
        ensure => directory,
        owner  => 'postgres',
        group  => 'postgres',
        mode   => '0700',
    }

    file { $osmosis_dir:
        ensure => directory,
        owner  => 'postgres',
        group  => 'postgres',
        mode   => '0755',
    }

    file { "${osmosis_dir}/configuration.txt":
        ensure  => present,
        owner   => 'postgres',
        group   => 'postgres',
        mode    => '0400',
        content => template('osm/osmosis_configuration.txt.erb'),
    }

    $sync_planet_cmd = inline_template("<%- data=@memoryfree.split(' '); multi={'MB' => 1, 'GB' => 1000}[data[1]]-%>/usr/bin/osmosis --read-replication-interval workingDirectory=<%= @osmosis_dir %> --simplify-change --write-xml-change - 2>/dev/null | /usr/bin/osm2pgsql -k -s -C <%= data[0].to_i/10*multi %> --number-processes <%= @processorcount %> -e15 -o <%= @expire_dir %>/expire.list.$(date \"+\\%Y\\%m\\%d\\%H\\%M\") --append -")
    cron { "planet_sync-${name}":
        environment => "JAVACMD_OPTIONS='-Dhttp.proxyHost=webproxy.eqiad.wmnet -Dhttp.proxyPort=8080'",
        command     => "${sync_planet_cmd} > /tmp/osmosis.log 2>&1",
        user        => 'postgres',
        hour        => $hour,
        minute      => $minute,
    }
    cron { "expire_old_planet_syncs-${name}":
        command => "/usr/bin/find ${expire_dir} -mtime +5 -exec rm {} \;",
        user    => 'postgres',
        hour    => $hour,
        minute  => $minute,
    }
}
