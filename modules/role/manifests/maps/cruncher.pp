# = Class: role::maps::cruncher
#
# Manages cruncher: tools to manipulate OSM and other maps data.
#
class role::maps::cruncher {

    include ::postgresql::master
    include ::postgresql::postgis
    include ::osm
    include ::osm::meddo

    postgresql::spatialdb { 'gis':
      require => Class['::postgresql::postgis'],
    }

}
