# Shared profile for front- and back-end puppetmasters.
#
# $config:  Dict merged with front- or back- specifics and then passed
#           to ::puppetmaster as $config
#
# $storeconfigs: Accepts values of 'puppetdb', 'activerecord', and 'none'
#
# $puppet_major_version: major version of puppet, defaults to undef.
class profile::puppetmaster::common (
    $base_config,
    $storeconfigs = hiera('profile::puppetmaster::common::storeconfigs', 'activerecord'),
    $puppet_major_version = hiera('puppet_major_version', 3),
) {
    include passwords::puppet::database

    $base_env_config = {
        'environmentpath'  => '$confdir/environments',
        'default_manifest' => '$confdir/manifests',
    }
    # Default to the future parser if on puppet 3
    if $puppet_major_version < 4 {
        $env_config = merge($base_env_config, {'parser' => 'future'})
    } else {
        $env_config = $base_env_config
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
