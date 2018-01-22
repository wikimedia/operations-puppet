# ==  Class puppetdb::app
#
# Sets up the puppetdb clojure app.
# This assumes you're using ...magic!
#
# === Parameters
#
# [*puppetdb_major_version*]
#   Major version of puppetdb to configure.
#   values: 4 or undef (default)
#
# [*puppetdb_package_variant*]
#   Package(er) variant.
#   values: "puppetlabs" or undef (default)

class puppetdb::app(
    $db_rw_host,
    $ca_path='/etc/ssl/certs/Puppet_Internal_CA.pem',
    $db_driver='postgres',
    $db_ro_host=undef,
    $db_user='puppetdb',
    $db_password=undef,
    $perform_gc=false,
    $jvm_opts='-Xmx4G',
    $bind_ip=undef,
    $ssldir=puppet_ssldir(),
    $command_processing_threads=16,
    Optional[Integer[4]] $puppetdb_major_version=undef,
    Optional[Enum['puppetlabs']] $puppetdb_package_variant=undef,
) {
    requires_os('debian >= jessie')

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

    if $db_driver == 'postgres' {
        $default_db_settings = {
            'classname'   => 'org.postgresql.Driver',
            'subprotocol' => 'postgresql',
            'username'    => 'puppetdb',
            'password'    => $db_password,
            'subname'     => "//${db_rw_host}:5432/puppetdb?ssl=true",
        }
    } elsif $db_driver == 'hsqldb' {
        $default_db_settings = {
            'classname'   => 'org.hsqldb.jdbcDriver',
            'subprotocol' => 'hsqldb',
            'subname'     => 'file:/var/lib/puppetdb/db/puppet.hsql;hsqldb.tx=mvcc;sql.syntax_pgs=true',
        }
    } else {
        fail("Unsupported db driver ${db_driver}")
    }

    if $perform_gc {
        $db_settings = merge(
            $default_db_settings,
            { 'report-ttl' => '1d', 'gc-interval' => '20' }
        )
    } else {
        $db_settings = $default_db_settings
    }

    puppetdb::config { 'database':
        settings => $db_settings,
    }

    #read db settings
    if $db_ro_host and $db_driver == 'postgres' {
        $read_db_settings = merge(
            $default_db_settings,
            {'subname' => "//${db_ro_host}:5432/puppetdb?ssl=true"}
        )
        puppetdb::config { 'read-database':
            settings => $read_db_settings,
        }
    }

    puppetdb::config { 'global':
        settings => {
            'vardir'         => '/var/lib/puppetdb',
            'logging-config' => '/etc/puppetdb/logback.xml',
        },
    }

    puppetdb::config { 'repl':
        settings => {'enabled' => false},
    }

    ::base::expose_puppet_certs { '/etc/puppetdb':
        ensure          => present,
        provide_private => true,
        user            => 'puppetdb',
        group           => 'puppetdb',
        ssldir          => $ssldir,
    }

    $jetty_settings = {
        'port'        => 8080,
        'ssl-port'    => 8081,
        'ssl-key'     => '/etc/puppetdb/ssl/server.key',
        'ssl-cert'    => '/etc/puppetdb/ssl/cert.pem',
        'ssl-ca-cert' => $ca_path,
    }
    if $bind_ip {
        $actual_jetty_settings = merge($jetty_settings, {'ssl-host' => $bind_ip})
    }
    else {
        $actual_jetty_settings = $jetty_settings
    }

    puppetdb::config { 'jetty':
        settings => $actual_jetty_settings,
        require  => Base::Expose_puppet_certs['/etc/puppetdb'],
    }

    # Systemd unit and service declaration
    systemd::service { 'puppetdb':
        ensure  => present,
        content => template('puppetdb/puppetdb.service.erb'),
        restart => true,
    }

    puppetdb::config { 'command-processing':
        settings => {
            'threads' => $command_processing_threads,
        },
    }

}
