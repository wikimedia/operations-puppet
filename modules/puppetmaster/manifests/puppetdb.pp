# Class puppetmaster::puppetdb
#
# Sets up a puppetdb instance and the corresponding database server.
# @param gc_interval This controls how often, in minutes, to compact the database.
#        The compaction process reclaims space and deletes unnecessary rows. If not
#        supplied, the default is every 20 minutes. If set to zero, all database GC
#        processes will be disabled.
# @param node_ttl Mark as ‘expired’ nodes that haven’t seen any activity (no new catalogs,
#        facts, or reports) in the specified amount of time. Expired nodes behave the same
#        as manually-deactivated nodes.
# @param node_purge_ttl Automatically delete nodes that have been deactivated or expired for
#        the specified amount of time
# @param report_ttl Automatically delete reports that are older than the specified amount of time.
# @param ca_content if present update the ca_path with the content
# @param master the primary db server
# @param port the port to to listen on
# @param jetty_port the port the  puppetdb app listens on
# @param jvm_opts options passed to the java vm
# @param ssldir the puippet ssl directory
# @param ca_path the to use for client auth
# @param puppetdb_pass the puppetdb password
# @param puppetdb_ro_pass the puppetdb read only password
# @param db_ro_host Postgres host for read queries
# @param log_level the log log_level
# @param tmpfs_stockpile_queue if true use tmpfs fort the stockpile queue
# @param facts_blacklist a liust of facts to blacklist from insertion to the db
# @param facts_blacklist_type wether the above blacklist entries are literal or regex
# @param ssl_verify_client this value indicates how to authenticate mtls users
# TODO: fold this class into profile::puppetdb
class puppetmaster::puppetdb(
    Stdlib::Host               $master,
    Stdlib::Port               $port                  = 443,
    Stdlib::Port               $jetty_port            = 8080,
    String                     $jvm_opts              ='-Xmx4G',
    Optional[Stdlib::Unixpath] $ssldir                = undef,
    Stdlib::Unixpath           $ca_path               = '/etc/ssl/certs/Puppet_Internal_CA.pem',
    String                     $puppetdb_pass         = '',
    String                     $puppetdb_ro_pass      = '',
    Optional[Stdlib::Host]     $db_ro_host            = undef,
    Puppetdb::Loglevel         $log_level             = 'info',
    Boolean                    $tmpfs_stockpile_queue = false,
    Array[String]              $facts_blacklist       = [],
    Enum['literal', 'regex']   $facts_blacklist_type  = 'literal',
    Integer[0]                 $gc_interval           = 20,
    Pattern[/\d+[dhms]/]       $node_ttl              = '7d',
    Pattern[/\d+[dhms]/]       $node_purge_ttl        = '14d',
    Pattern[/\d+[dhms]/]       $report_ttl            = '1d',
    Nginx::SSL::Verify_client  $ssl_verify_client     = 'optional',
    Optional[String[1]]        $ca_content            = undef,
) {

    ## TLS Termination
    # Set up nginx as a reverse-proxy
    # TODO: consider using profile::pki::get_cert
    puppet::expose_agent_certs { '/etc/nginx':
        ensure          => present,
        provide_private => true,
        ssldir          => $ssldir,
    }
    if $ca_content {
        file { $ca_path:
            ensure  => file,
            content => $ca_content,
            mode    => '0444',
        }
    }

    $ssl_settings = ssl_ciphersuite('nginx', 'mid')
    include sslcert::dhparam
    nginx::site { 'puppetdb':
        ensure  => present,
        content => template('puppetmaster/nginx-puppetdb.conf.erb'),
        require => [
            Class['::sslcert::dhparam'],
            Puppet::Expose_agent_certs['/etc/nginx'],
        ],
    }

    # T209709
    nginx::status_site { 'status':
        port    => 10080,
        require => Puppet::Expose_agent_certs['/etc/nginx'],
    }

    class { 'puppetdb::app':
        db_rw_host            => $master,
        db_ro_host            => $db_ro_host,
        db_password           => $puppetdb_pass,
        db_ro_password        => $puppetdb_ro_pass,
        jvm_opts              => $jvm_opts,
        ssldir                => $ssldir,
        ca_path               => $ca_path,
        log_level             => $log_level,
        tmpfs_stockpile_queue => $tmpfs_stockpile_queue,
        facts_blacklist       => $facts_blacklist,
        facts_blacklist_type  => $facts_blacklist_type,
        gc_interval           => $gc_interval,
        node_ttl              => $node_ttl,
        node_purge_ttl        => $node_purge_ttl,
        report_ttl            => $report_ttl,
    }
}
