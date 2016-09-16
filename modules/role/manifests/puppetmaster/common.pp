class role::puppetmaster::common ( $base_config ) {
    include passwords::puppet::database
    $activerecord_config =   {
        'storeconfigs'      => true,
        'thin_storeconfigs' => true,
        'dbadapter'         => 'mysql',
        'dbuser'            => 'puppet',
        'dbpassword'        => $passwords::puppet::database::puppet_production_db_pass,
        'dbserver'          => 'm1-master.eqiad.wmnet',
        'dbconnections'     => '256',
    }

    $puppetdb_config = {
        storeconfigs         => true,
        storeconfigs_backend => 'puppetdb',
        reports              => 'store,puppetdb',
    }

    $use_puppetdb = hiera('puppetmaster::config::use_puppetdb', false)

    if $use_puppetdb {
        $puppetdb_host = hiera('puppetmaster::config::puppetdb_host')
        class { 'puppetmaster::puppetdb::client':
            host => $puppetdb_host,
        }
        $config = merge($base_config, $puppetdb_config)
    }
    else {
        $config = merge($base_config, $activerecord_config)
    }
}
