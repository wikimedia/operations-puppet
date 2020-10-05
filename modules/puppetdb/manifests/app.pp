# ==  Class puppetdb::app
#
# Sets up the puppetdb clojure app.
# This assumes you're using ...magic!
#
# === Parameters
#

class puppetdb::app(
    String                        $jvm_opts                   = '-Xmx4G',
    String                        $db_user                    = 'puppetdb',
    String                        $db_driver                  = 'postgres',
    Stdlib::Unixpath              $ssldir                     = puppet_ssldir(),
    Stdlib::Unixpath              $ca_path                    = '/etc/ssl/certs/Puppet_Internal_CA.pem',
    Stdlib::Unixpath              $vardir                     = '/var/lib/puppetdb',
    Stdlib::Unixpath              $stockpile_queue_dir        = "${vardir}/stockpile/cmd/q",
    Boolean                       $tmpfs_stockpile_queue      = false,
    Boolean                       $perform_gc                 = false,
    Integer                       $command_processing_threads = 16,
    Puppetdb::Loglevel            $log_level                  = 'info',
    Optional[String]              $db_rw_host                 = undef,
    Optional[Stdlib::IP::Address] $bind_ip                    = undef,
    Optional[String]              $db_ro_host                 = undef,
    Optional[String]              $db_password                = undef,
) {
    ## PuppetDB installation

    require_package('puppetdb')

    file { $vardir:
        ensure => directory,
        owner  => 'puppetdb',
        group  => 'puppetdb',
        mode   => '0755',
    }
    $stockpile_queue_dir_ensure = $tmpfs_stockpile_queue ? {
        true    => 'mounted',
        default => 'absent',
    }
    mount {$stockpile_queue_dir:
        ensure => $stockpile_queue_dir_ensure,
        atboot => true,
        device => 'tmpfs',
        fstype => 'tmpfs',
        notify => Service['puppetdb'],
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

    $postgres_uri = "ssl=true&sslfactory=org.postgresql.ssl.jdbc4.LibPQFactory&sslmode=verify-full&sslrootcert=${ca_path}"
    $postgres_rw_db_subname = "//${db_rw_host}:5432/puppetdb?${postgres_uri}"
    $postgres_ro_db_subname = "//${db_ro_host}:5432/puppetdb?${postgres_uri}"

    $default_db_settings = {
        'postgres' => {
            'classname'   => 'org.postgresql.Driver',
            'subprotocol' => 'postgresql',
            'username'    => 'puppetdb',
            'password'    => $db_password,
            'subname'     => $postgres_rw_db_subname,
        },
        'hsqldb'   => {
            'classname'   => 'org.hsqldb.jdbcDriver',
            'subprotocol' => 'hsqldb',
            'subname'     => 'file:/var/lib/puppetdb/db/puppet.hsql;hsqldb.tx=mvcc;sql.syntax_pgs=true',
        }
    }[$db_driver]
    unless $default_db_settings {
        fail("Unsupported db driver ${db_driver}")
    }
    $db_settings = $perform_gc ? {
        true    => merge($default_db_settings, { 'report-ttl' => '1d', 'gc-interval' => '20' }),
        default => $default_db_settings
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

    base::expose_puppet_certs { '/etc/puppetdb':
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
    $actual_jetty_settings = $bind_ip ? {
        undef   => $jetty_settings,
        default => merge($jetty_settings, {'ssl-host' => $bind_ip}),
    }

    puppetdb::config { 'jetty':
        settings => $actual_jetty_settings,
        require  => Base::Expose_puppet_certs['/etc/puppetdb'],
    }

    puppetdb::config { 'command-processing':
        settings => {
            'threads' => $command_processing_threads,
        },
    }
    file {'/etc/puppetdb/logback.xml':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('puppetdb/logback.xml.erb'),
    }
}
