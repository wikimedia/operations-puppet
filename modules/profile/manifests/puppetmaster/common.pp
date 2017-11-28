# Shared profile for front- and back-end puppetmasters.
#
# $config:  Dict merged with front- or back- specifics and then passed
#           to ::puppetmaster as $config
#
# $directory_environments: boolean, when True adds boilerplate environment config
#
# $storeconfigs: Accepts values of 'puppetdb', 'activerecord', and 'none'

class profile::puppetmaster::common (
    $base_config,
    $directory_environments = hiera('profile::puppetmaster::common::directory_environments', false),
    $storeconfigs = hiera('profile::puppetmaster::common::storeconfigs', 'activerecord'),
) {
    include passwords::puppet::database

    if $directory_environments {
        $env_config = {
            'environmentpath' => '$confdir/environments',
            'default_manifest' => '$confdir/manifests/site.pp'
        }
    } else {
        $env_config = {}
    }

    $activerecord_config =   {
        'storeconfigs'      => true,
        'thin_storeconfigs' => true,
    }
    # Note: We are going to need this anyway regardless of
    # puppetdb/active_record use for the configuration of servermon report
    # handler
    $active_record_db = {
        'dbadapter'         => 'mysql',
        'dbuser'            => 'puppet',
        'dbpassword'        => $passwords::puppet::database::puppet_production_db_pass,
        'dbserver'          => 'm1-master.eqiad.wmnet',
        'dbconnections'     => '256',
    }

    $puppetdb_config = {
        storeconfigs         => true,
        storeconfigs_backend => 'puppetdb',
        reports              => 'servermon',
    }

    if $storeconfigs == 'puppetdb' {
        $puppetdb_host = hiera('profile::puppetmaster::common::puppetdb_host')
        class { 'puppetmaster::puppetdb::client':
            host => $puppetdb_host,
        }
        $config = merge($base_config, $puppetdb_config, $active_record_db, $env_config)
    } elsif $storeconfigs == 'activerecord' {
            $config = merge($base_config, $activerecord_config, $active_record_db, $env_config)
    } else {
            $config = merge($base_config, $env_config)
    }
}
