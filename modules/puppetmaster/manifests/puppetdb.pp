# Class puppetmaster::puppetdb
#
# Sets up a puppetdb instance and the corresponding database server.
class puppetmaster::puppetdb($master) {
    require_os('Debian >= jessie')

    $puppetdb_pass = hiera('puppetdb::password::rw')

    # set up the postgres database
    class { 'puppetmaster::puppetdb::databases':
        master => $master,
    }

    # Set up nginx as a reverse-proxy
    class { 'nginx::simple_tlsproxy':
        backend_port => 8080,
        site_name    => $::fqdn,
    }

    package { 'puppetdb':
        ensure => present,
    }

    file { '/etc/puppetdb/conf.d':
        ensure  => directory,
        owner   => 'puppetdb',
        group   => 'root',
        mode    => '0750',
        require => Package['puppetdb']
    }

    $default_db_settings = {
        'classname'   => 'org.postgresql.Driver',
        'subprotocol' => 'postgresql',
        'username'    => 'puppetdb',
        'password'    => $puppetdb_pass,
    }

    # Read-write connections go to the master.
    # Only the master should be performing housekeeping work
    if ($master == $::fqdn) {
        $db_settings = merge(
            $default_db_settings,
            {
                'node-ttl'    => '14d',
                'report-ttl'  => '1d',
                'gc-interval' => '20m',
                'subname'     => "//${::master}:5432/puppetdb?ssl=true",
            },
        )
    } else {
        $db_settings = merge(
            $default_db_settings,
            {'subname'     => "//${::master}:5432/puppetdb?ssl=true"},
        )
    }

    # The read database is always the local one.
    $read_db_settings = merge(
        $default_db_settings,
        {'subname'     => "//${::fqdn}:5432/puppetdb?ssl=true"},
    )

    ::base::expose_puppet_certs { '/etc/puppetdb':
        ensure          => present,
        provide_private => true,
        user            => 'puppetdb',
        group           => 'puppetdb',

    }

    $main_settings = {
        'database'      => $db_settings,
        'read-database' => $read_db_settings,
        'jetty'         => {
            'port' => '8080',
            'ssl-port' => '8081',
            'ssl-key' => '/etc/puppetdb/ssl/server.key',
            'ssl-cert' => '/etc/puppetdb/ssl/cert.pem',
            'ssl-ca-cert' => '/etc/ssl/certs/Puppet_Internal_CA.pem',
        }
    }

    file { '/etc/puppetdb/conf.d/main.ini':
        content => ini($main_settings),
        owner   => 'puppetdb',
        group   => 'root',
        mode    => '0640',
        before  => Base::Service_unit['puppetdb'],
    }

    base::service_unit { 'puppetdb':
        ensure  => present,
        systemd => true,
    }
}
