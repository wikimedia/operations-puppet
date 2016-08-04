# vim: set tabstop=4 shiftwidth=4 softtabstop=4 expandtab textwidth=80 smarttab

class role::puppetmaster::frontend {
    include passwords::puppet::database

    include role::backup::host
    backup::set { 'var-lib-puppet-ssl': }
    backup::set { 'var-lib-puppet-volatile': }

    system::role { 'puppetmaster':
        description => 'Puppetmaster frontend'
    }

    # Puppet frontends are git masters at least for their datacenter

    class { '::puppetmaster':
        server_type   => 'frontend',
        is_git_master => true,
        workers       => [
                          {
                          'worker'     => 'palladium.eqiad.wmnet',
                          'loadfactor' => 10,
                          },
                          {
                          'worker'     => 'strontium.eqiad.wmnet',
                          'loadfactor' => 20,
                          },
                          {
                          'worker'     => 'rhodium.eqiad.wmnet',
                          'loadfactor' => 20,
                          },
        ],
        config        => {
            'storeconfigs'      => true, # Required by thin_storeconfigs on puppet 3.x
            'thin_storeconfigs' => true,
            'dbadapter'         => 'mysql',
            'dbuser'            => 'puppet',
            'dbpassword'        => $passwords::puppet::database::puppet_production_db_pass,
            'dbserver'          => 'm1-master.eqiad.wmnet',
        }
    }

    ferm::service { 'puppetmaster-backend':
        proto => 'tcp',
        port  => 8141,
    }

    ferm::service { 'puppetmaster-frontend':
        proto => 'tcp',
        port  => 8140,
    }
}
