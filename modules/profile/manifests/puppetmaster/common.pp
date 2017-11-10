# Shared profile for front- and back-end puppetmasters.
#
# $base_config:  Dict merged with front- or back- specifics and then passed
#           to ::puppetmaster as $config
#
# $directory_environments: boolean, when True adds boilerplate environment config
#
# $storeconfigs: Accepts values of 'puppetdb', 'activerecord', and 'none'
#
# $puppet_db_user: Sets username for active records mysql db
#
# $puppet_db_server: Sets the server ip or hostname to connect to
#
# $puppet_db_password: Sets password for active records mysql db

class profile::puppetmaster::common (
    $base_config = hiera('profile::puppetmaster::common::base_config', false),
    $directory_environments = hiera('profile::puppetmaster::common::directory_environments', false),
    $storeconfigs = hiera('profile::puppetmaster::common::storeconfigs', 'activerecord'),
    $puppet_db_user = hiera('puppetmaster_db_user', 'puppet'),
    $puppet_db_server = hiera('puppetmaster_db_server', 'm1-master.eqiad.wmnet'),
    $puppet_db_password = hiera('puppetmaster_db_password', false)
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
    if $puppet_db_password != false {
      $pass = $puppet_db_password
    } else {
      $pass = $passwords::puppet::database::puppet_production_db_pass
    }

    $active_record_db = {
        'dbadapter'         => 'mysql',
        'dbuser'            => $puppet_db_user,
        'dbpassword'        => $puppet_db_password,
        'dbserver'          => $puppet_db_server,
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
