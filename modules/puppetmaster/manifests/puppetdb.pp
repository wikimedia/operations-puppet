# Class puppetmaster::puppetdb
#
# Sets up a puppetdb instance and the corresponding database server.
class puppetmaster::puppetdb($master, $port=443, $jetty_port=8080) {
    requires_os('debian >= jessie')

    $puppetdb_pass = hiera('puppetdb::password::rw')

    ## TLS Termination
    # Set up nginx as a reverse-proxy
    ::base::expose_puppet_certs { '/etc/nginx':
        ensure          => present,
        provide_private => true,
        require         => Class['nginx'],
    }

    $ssl_settings = ssl_ciphersuite('nginx', 'mid')
    include ::sslcert::dhparam
    ::nginx::site { 'puppetdb':
        ensure  => present,
        content => template('puppetmaster/nginx-puppetdb.conf.erb'),
        require => Class['::sslcert::dhparam'],
    }

    diamond::collector::nginx{ $::fqdn:
        port => 10080,
    }

    ## PuppetDB installation

    package { 'puppetdb':
        ensure => present,
    }


    ## Configuration

    file { '/etc/puppetdb/conf.d':
        ensure  => directory,
        owner   => 'puppetdb',
        group   => 'root',
        mode    => '0750',
        recurse => true,
        require => Package['puppetdb'],
    }

    # Ensure the default debian config file is not there

    file { '/etc/puppetdb/conf.d/config.ini':
        ensure => absent,
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
                'gc-interval' => '20',
                'subname'     => "//${master}:5432/puppetdb?ssl=true",
            }
        )
    } else {
        $db_settings = merge(
            $default_db_settings,
            {'subname' => "//${master}:5432/puppetdb?ssl=true"}
        )
    }

    puppetmaster::puppetdb::config { 'database':
        settings => $db_settings,
    }

    # The read database is always the local one.
    $read_db_settings = merge(
        $default_db_settings,
        {
            'subname' => "//${::fqdn}:5432/puppetdb?ssl=true"
        }
    )
    puppetmaster::puppetdb::config { 'read-database':
        settings => $read_db_settings,
    }

    ::base::expose_puppet_certs { '/etc/puppetdb':
        ensure          => present,
        provide_private => true,
        user            => 'puppetdb',
        group           => 'puppetdb',

    }

    puppetmaster::puppetdb::config { 'jetty':
        settings => {
            'port'        => 8080,
            'ssl-port'    => 8081,
            'ssl-key'     => '/etc/puppetdb/ssl/server.key',
            'ssl-cert'    => '/etc/puppetdb/ssl/cert.pem',
            'ssl-ca-cert' => '/etc/ssl/certs/Puppet_Internal_CA.pem',
        },
        require  => Base::Expose_puppet_certs['/etc/puppetdb'],
    }

    puppetmaster::puppetdb::config { 'global':
        settings => {
            'vardir'         => '/var/lib/puppetdb',
            'logging-config' => '/etc/puppetdb/logback.xml',
        },
    }

    puppetmaster::puppetdb::config { 'repl':
        settings => {'enabled' => false},
    }

    ## Enable the service itself
    base::service_unit { 'puppetdb':
        ensure  => present,
        systemd => true,
    }
}
