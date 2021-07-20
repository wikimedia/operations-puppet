# ==  Class puppetdb::app
#
# Sets up the puppetdb clojure app.
# This assumes you're using ...magic!
#
# === Parameters
#
# @param gc_interval This controls how often, in minutes, to compact the database.
#        The compaction process reclaims space and deletes unnecessary rows. If not
#        supplied, the default is every 60 minutes. If set to zero, all database GC
#        processes will be disabled.
# @param node_ttl Mark as ‘expired’ nodes that haven’t seen any activity (no new catalogs,
#        facts, or reports) in the specified amount of time. Expired nodes behave the same
#        as manually-deactivated nodes.
# @param node_purge_ttl Automatically delete nodes that have been deactivated or expired for
#        the specified amount of time
# @param report_ttl Automatically delete reports that are older than the specified amount of time.
#
class puppetdb::app(
    String                        $jvm_opts                   = '-Xmx4G',
    String                        $db_user                    = 'puppetdb',
    Enum['hsqldb', 'postgres']    $db_driver                  = 'postgres',
    Stdlib::Unixpath              $ssldir                     = puppet_ssldir(),
    Stdlib::Unixpath              $ca_path                    = '/etc/ssl/certs/Puppet_Internal_CA.pem',
    Stdlib::Unixpath              $vardir                     = '/var/lib/puppetdb',
    Stdlib::Unixpath              $stockpile_queue_dir        = "${vardir}/stockpile/cmd/q",
    Boolean                       $tmpfs_stockpile_queue      = false,
    Integer                       $command_processing_threads = 16,
    Puppetdb::Loglevel            $log_level                  = 'info',
    Array[String]                 $facts_blacklist            = [],
    Enum['literal', 'regex']      $facts_blacklist_type       = 'literal',
    Integer[0]                    $gc_interval                = 20,
    Pattern[/\d+[dhms]/]          $node_ttl                   = '7d',
    Pattern[/\d+[dhms]/]          $node_purge_ttl             = '14d',
    Pattern[/\d+[dhms]/]          $report_ttl                 = '1d',
    Stdlib::Host                  $db_rw_host                 = $facts['fqdn'],
    Optional[Stdlib::IP::Address] $bind_ip                    = undef,
    Optional[String]              $db_ro_host                 = undef,
    Optional[String]              $db_password                = undef,
    Optional[String]              $db_ro_password             = undef,
) {
    # PuppetDB installation

    ensure_packages('puppetdb')

    file { $vardir:
        ensure => directory,
        owner  => 'puppetdb',
        group  => 'puppetdb',
        mode   => '0755',
    }
    $stockpile_mount_ensure = $tmpfs_stockpile_queue ? {
        true    => 'mounted',
        default => 'absent',
    }
    mount {$stockpile_queue_dir:
        ensure => $stockpile_mount_ensure,
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
    file { '/etc/puppetdb':
        ensure  => directory,
        require => Package['puppetdb'],
    }
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

    $db_driver_settings = {
        'postgres' => {
            'classname'   => 'org.postgresql.Driver',
            'subprotocol' => 'postgresql',
        },
        'hsqldb'   => {
            'classname'   => 'org.hsqldb.jdbcDriver',
            'subprotocol' => 'hsqldb',
            'subname'     => 'file:/var/lib/puppetdb/db/puppet.hsql;hsqldb.tx=mvcc;sql.syntax_pgs=true',
        }
    }[$db_driver]

    $db_settings = $db_driver_settings + {
        'report-ttl'     => $report_ttl,
        'gc-interval'    => $gc_interval,
        'node-ttl'       => $node_ttl,
        'node-purge-ttl' => $node_purge_ttl,
        'subname'        => $postgres_rw_db_subname,
        'username'       => 'puppetdb',
        'password'       => $db_password,
    }
    $read_db_settings = $db_driver_settings + {
        'subname'  => $postgres_ro_db_subname,
        'username' => 'puppetdb_ro',
        'password' => $db_ro_password,
    }

    puppetdb::config { 'database':
        settings => $db_settings,
    }
    if $db_ro_host and $db_driver == 'postgres' {
        puppetdb::config { 'read-database':
            settings => $read_db_settings,
        }
    }

    puppetdb::config { 'global':
        settings => {
            'vardir'         => $vardir,
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
    unless $facts_blacklist.empty {
        puppetdb::config { 'facts-blacklist':
            settings => {
                'facts-blacklist-type' => $facts_blacklist_type,
                'facts-blacklist'      => $facts_blacklist.join(', '),
            },
        }
    }
    file {'/etc/puppetdb/logback.xml':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('puppetdb/logback.xml.erb'),
    }
}
