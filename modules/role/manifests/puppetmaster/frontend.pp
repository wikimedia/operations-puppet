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

    $ca_server = hiera('puppetmaster::ca_server', 'palladium.eqiad.wmnet')
    $ca = $ca_server ? {
        # lint:ignore:quoted_booleans
        $::fqdn => 'true',
        default => 'false',
        # lint:endignore
    }
    class { '::puppetmaster':
        server_type   => 'frontend',
        is_git_master => true,
        workers       => [
            {
            'worker'     => 'rhodium.eqiad.wmnet',
            'loadfactor' => 20,
            },
        ],
        config        => {
            'ca'                => $ca,
            'ca_server'         => $ca_server,
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
