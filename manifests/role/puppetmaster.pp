# vim: set tabstop=4 shiftwidth=4 softtabstop=4 expandtab textwidth=80 smarttab

class role::puppetmaster::frontend {
    include passwords::puppet::database

    include role::backup::host
    backup::set { 'var-lib-puppet-ssl': }
    backup::set { 'var-lib-puppet-volatile': }

    system::role { 'puppetmaster':
        description => 'Puppetmaster frontend'
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

    ferm::service { 'puppetmaster-backend':
        proto  => 'tcp',
        port   => 8141,
        srange => '$INTERNAL',
    }
}

class role::puppetmaster::labs {
    include network::constants

    $labs_ranges = [
        $network::constants::all_network_subnets['production']['eqiad']['private']['labs-instances1-a-eqiad']['ipv4'],
        $network::constants::all_network_subnets['production']['eqiad']['private']['labs-instances1-b-eqiad']['ipv4'],
        $network::constants::all_network_subnets['production']['eqiad']['private']['labs-instances1-c-eqiad']['ipv4'],
        $network::constants::all_network_subnets['production']['eqiad']['private']['labs-instances1-d-eqiad']['ipv4'],
    ]

    include ldap::role::config::labs
    $ldapconfig = $ldap::role::config::labs::ldapconfig
    $basedn = $ldapconfig['basedn']

    # Only allow puppet access from the instances
    $allow_from = $::realm ? {
        'production' => flatten([$labs_ranges, '208.80.154.14']),
        'labs' => [ '192.168.0.0/21' ],
    }

    class { '::puppetmaster':
        server_name => hiera('labs_puppet_master'),
        allow_from  => $allow_from,
        config      => {
            'thin_storeconfigs' => false,
            'node_terminus'     => 'ldap',
            'ldapserver'        => $ldapconfig['servernames'][0],
            'ldapbase'          => "ou=hosts,${basedn}",
            'ldapstring'        => '(&(objectclass=puppetClient)(associatedDomain=%s))',
            'ldapuser'          => $ldapconfig['proxyagent'],
            'ldappassword'      => $ldapconfig['proxypass'],
            'ldaptls'           => true,
            'autosign'          => true,
        };
    }

    if ! defined(Class['puppetmaster::certmanager']) {
        class { 'puppetmaster::certmanager':
            remote_cert_cleaner => hiera('labs_certmanager_hostname'),
        }
    }
}
