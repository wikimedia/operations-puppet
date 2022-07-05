# SPDX-License-Identifier: Apache-2.0
class osm::osm2pgsql (
    Boolean $use_proxy,
    String $proxy_host,
    Stdlib::Port $proxy_port,
    String $osm_log_dir                     = '/srv/osmosis',
    String $osmosis_dir                     = '/srv/osmosis',
    String $period                          = 'minute',
    Boolean $flat_nodes                     = false,
    Integer $expire_levels                  = 15,
    Integer $memory_limit                   = floor($::memorysize_mb) / 12,
    Integer $num_threads                    = $::processorcount,
    String $input_reader_format             = 'xml',
    String $expire_dir                      = '/srv/osm_expire',
    Optional[String] $postreplicate_command = undef,
) {
    file {
        default:
            ensure => file,
            owner  => 'root',
            group  => 'root',
            mode   => '0755';
        '/usr/local/bin/osm-initial-import':
            source => 'puppet:///modules/profile/maps/osm-initial-import';
        $osmosis_dir:
            ensure => directory,
            owner  => 'osmupdater',
            mode   => '0775',
            group  => 'osm';
        '/usr/local/bin/replicate-osm':
            mode    => '0555',
            content => template('osm/replicate-osm.erb');
        "${osmosis_dir}/configuration.txt":
            mode    => '0444',
            content => template('osm/osmosis_configuration.txt.erb');
        "${osmosis_dir}/nodes.bin":
            owner => 'osmupdater',
            mode  => '0775',
            group => 'osm',
    }

    logrotate::conf { 'planetsync':
        ensure  => present,
        content => template('osm/planetsync-logrotate.conf.erb'),
    }

}
