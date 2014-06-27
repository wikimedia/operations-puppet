# vim: set tabstop=4 shiftwidth=4 softtabstop=4 expandtab textwidth=80 smarttab

class role::puppetmaster::config {
        $allow_from = [
            '*.wikimedia.org',
            '*.pmtpa.wmnet',
            '*.eqiad.wmnet',
            '*.ulsfo.wmnet',
            '*.esams.wmnet',
        ]
}

class role::puppetmaster::frontend {
    include role::puppetmaster::config
    include passwords::puppet::database

    class { '::puppetmaster':
        allow_from  => $role::puppetmaster::config::allow_from,
        server_type => 'frontend',
        workers     =>  [
                        { 'worker' => 'palladium.eqiad.wmnet', },
                        { 'worker' => 'strontium.eqiad.wmnet', },
        ],
        config      => {
            'storeconfigs'      => true, # Required by thin_storeconfigs on puppet 3.x
            'thin_storeconfigs' => true,
            'dbadapter'         => 'mysql',
            'dbuser'            => 'puppet',
            'dbpassword'        => $passwords::puppet::database::puppet_production_db_pass,
            'dbserver'          => 'db1001.eqiad.wmnet',
        }
    }
}

class role::puppetmaster::backend {
    include role::puppetmaster::config
    include passwords::puppet::database

    class { '::puppetmaster':
        allow_from  => $role::puppetmaster::config::allow_from,
        server_type => 'backend',
        config      => {
            'storeconfigs'      => true, # Required by thin_storeconfigs on puppet 3.x
            'thin_storeconfigs' => true,
            'ca'                => 'false',
            'ca_server'         => 'palladium.eqiad.wmnet',
            'dbadapter'         => 'mysql',
            'dbuser'            => 'puppet',
            'dbpassword'        => $passwords::puppet::database::puppet_production_db_pass,
            'dbserver'          => 'db1001.eqiad.wmnet',
            'dbconnections'     => '256',
        }
    }
}
