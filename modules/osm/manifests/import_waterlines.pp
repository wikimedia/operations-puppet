# Definition: osm::import_waterlines
#
# Sets up waterlines
# Parameters:
#    * database - postgres database name
#    * use_proxy - when set to true, proxy is used
#    * proxy - web proxy used for downloading shapefiles
class osm::import_waterlines (
    Boolean $use_proxy,
    String $proxy_host,
    Stdlib::Port $proxy_port,
    String $database = 'gis',
) {

    $log_dir = '/var/log/waterlines'

    $proxy_opt = $use_proxy ? {
        false   => '',
        default => "-x ${proxy_host}:${proxy_port}",
    }

    file { '/usr/local/bin/import_waterlines':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        content => template('osm/import_waterlines.erb'),
    }

    file { $log_dir:
        ensure => directory,
        owner  => 'postgres',
        group  => 'postgres',
        mode   => '0755',
    }

    logrotate::conf { 'import_waterline':
        ensure  => present,
        content => template('osm/waterlines.logrotate.erb'),
    }

    cron { 'import_waterlines':
        ensure   => present,
        hour     => 9,
        minute   => 13,
        monthday => 1,
        user     => 'postgres',
        command  => "/usr/local/bin/import_waterlines >> ${log_dir}/import.log 2>&1",
    }
}
