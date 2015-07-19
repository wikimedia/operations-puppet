# Definition: osm::import_waterlines
#
# Sets up waterlines
# Parameters:
#    * database - postgres database name
#    * proxy - web proxy used for downloading shapefiles
class osm::import_waterlines (
    $database = 'gis',
    $proxy = 'webproxy.eqiad.wmnet:8080'
) {
    file { '/usr/local/bin/import_waterlines':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => 0555,
        content => template( 'osm/import_waterlines.erb' ),
    }

    cron { 'import_waterlines':
        ensure  => present,
        hour    => 17,
        minute  => 0,
        weekday => 'Tue',
        user    => 'postgres',
        command => '/usr/local/bin/import_waterlines',
        require => [File['/usr/local/bin/import_waterlines'], Class['osm']],
    }
}
