# vim: set tabstop=4 shiftwidth=4 softtabstop=4 expandtab textwidth=80 smarttab

class role::puppetmaster::backend {
    include passwords::puppet::database
    include base::firewall

    system::role { 'puppetmaster':
        description => 'Puppetmaster backend'
    }

    class { '::puppetmaster':
        server_type => 'backend',
        config      => {
            'storeconfigs'      => true, # Required by thin_storeconfigs on puppet 3.x
            'thin_storeconfigs' => true,
            # lint:ignore:quoted_booleans
            # Not a simple boolean, this must be quoted.
            'ca'                => 'false',
            # lint:endignore
            'ca_server'         => 'palladium.eqiad.wmnet',
            'dbadapter'         => 'mysql',
            'dbuser'            => 'puppet',
            'dbpassword'        => $passwords::puppet::database::puppet_production_db_pass,
            'dbserver'          => 'm1-master.eqiad.wmnet',
            'dbconnections'     => '256',
        }
    }

    ferm::service { 'puppetmaster-backend':
        proto  => 'tcp',
        port   => 8141,
    }

    $puppetmaster_hostname = hiera('puppetmaster')
    ferm::service { 'ssh_puppet_merge':
        proto  => 'tcp',
        port   => '22',
        srange => "@resolve(${puppetmaster_hostname})"
    }
}
