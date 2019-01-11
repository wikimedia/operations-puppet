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

class puppetdb::app(
    Optional[String] $db_rw_host,
    String $jvm_opts='-Xmx4G',
    String $db_user='puppetdb',
    String $db_driver='postgres',
    String $ssldir=puppet_ssldir(),
    String $ca_path='/etc/ssl/certs/Puppet_Internal_CA.pem',
    Boolean $perform_gc=false,
    Integer $command_processing_threads=16,
    Optional[String] $bind_ip=undef,
    Optional[String] $db_ro_host=undef,
    Optional[String] $db_password=undef,
    Optional[Integer[4]] $puppetdb_major_version=undef,
) {
    ## PuppetDB installation

    require_package('puppetdb')

    # Temporary conditional to support puppetlabs puppetdb 4 package
    # clean up after puppetdb upgrade
    if $puppetdb_major_version == 4 {

        # Symlink /etc/puppetdb to /etc/puppetlabs/puppetdb
        file { '/etc/puppetdb':
            ensure => link,
            target => '/etc/puppetlabs/puppetdb',
        }

        file { '/var/lib/puppetdb':
            ensure => directory,
            owner  => 'puppetdb',
            group  => 'puppetdb',
        }

        file { '/etc/default/puppetdb':
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            content => template('puppetdb/etc/default/puppetdb.erb'),
        }

        service { 'puppetdb':,
            ensure => running,
            enable => true,
        }

    }

    ## Configuration

    file { '/etc/puppetdb/conf.d':
        ensure  => directory,
        owner   => 'puppetdb',
        group   => 'root',
        mode    => '0750',
        recurse => true,
    }

    # Ensure the default debian config file is not there

    file { '/etc/puppetdb/conf.d/config.ini':
        ensure => absent,
    }

    if $puppetdb_major_version == 4 {
        $postgres_rw_db_subname = "//${db_rw_host}:5432/puppetdb?ssl=true&sslfactory=org.postgresql.ssl.jdbc4.LibPQFactory&sslmode=verify-full&sslrootcert=${ca_path}"
        $postgres_ro_db_subname = "//${db_ro_host}:5432/puppetdb?ssl=true&sslfactory=org.postgresql.ssl.jdbc4.LibPQFactory&sslmode=verify-full&sslrootcert=${ca_path}"
    } else {
        $postgres_rw_db_subname = "//${db_rw_host}:5432/puppetdb?ssl=true"
        $postgres_ro_db_subname = "//${db_ro_host}:5432/puppetdb?ssl=true&sslfactory=org.postgresql.ssl.jdbc4.LibPQFactory&sslmode=verify-full&sslrootcert=${ca_path}"
    }

    if $db_driver == 'postgres' {
        $default_db_settings = {
            'classname'   => 'org.postgresql.Driver',
            'subprotocol' => 'postgresql',
            'username'    => 'puppetdb',
            'password'    => $db_password,
            'subname'     => $postgres_rw_db_subname,
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
            {'subname' => $postgres_ro_db_subname}
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

    # Temporary conditional to support puppetlabs puppetdb 4 package
    # clean up after puppetdb upgrade
    unless $puppetdb_major_version == 4 {

        # Systemd unit and service declaration
        systemd::service { 'puppetdb':
            ensure  => present,
            content => template('puppetdb/puppetdb.service.erb'),
            restart => true,
        }

    }

    puppetdb::config { 'command-processing':
        settings => {
            'threads' => $command_processing_threads,
        },
    }

}
