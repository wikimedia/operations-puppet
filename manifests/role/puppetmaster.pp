# vim: set tabstop=4 shiftwidth=4 softtabstop=4 expandtab textwidth=80 smarttab

class role::puppetmaster::frontend {
    include passwords::puppet::database

    include role::backup::host
    backup::set { 'var-lib-puppet-ssl': }
    backup::set { 'var-lib-puppet-volatile': }

    system::role { 'puppetmaster':
        description => 'Puppetmaster backend'
    }

    class { '::puppetmaster':
        server_type => 'frontend',
        workers     =>  [
                        {
                            'worker' => 'palladium.eqiad.wmnet',
                            'loadfactor' => 10,
                        },
                        {
                            'worker' => 'strontium.eqiad.wmnet',
                            'loadfactor' => 20,
                        },
        ],
        config      => {
            'storeconfigs'      => true, # Required by thin_storeconfigs on puppet 3.x
            'thin_storeconfigs' => true,
            'dbadapter'         => 'mysql',
            'dbuser'            => 'puppet',
            'dbpassword'        => $passwords::puppet::database::puppet_production_db_pass,
            'dbserver'          => 'm1-master.eqiad.wmnet',
        }
    }

    Class['role::access_new_install'] -> Class['::puppetmaster::scripts::frontend']
}

class role::puppetmaster::backend {
    include passwords::puppet::database

    system::role { 'puppetmaster':
        description => 'Puppetmaster backend'
    }

    class { '::puppetmaster':
        server_type => 'backend',
        config      => {
            'storeconfigs'      => true, # Required by thin_storeconfigs on puppet 3.x
            'thin_storeconfigs' => true,
            'ca'                => 'false',
            'ca_server'         => 'palladium.eqiad.wmnet',
            'dbadapter'         => 'mysql',
            'dbuser'            => 'puppet',
            'dbpassword'        => $passwords::puppet::database::puppet_production_db_pass,
            'dbserver'          => 'm1-master.eqiad.wmnet',
            'dbconnections'     => '256',
        }
    }
}
