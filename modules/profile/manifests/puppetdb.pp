# SPDX-License-Identifier: Apache-2.0
# @summary profile to configure puppetdb
# @param puppetmasters the list of puppetmasters
# @param master the write instance
# @param jvm_opts additional jvm options
# @param elk_logging enable elk_logging
# @param ca_path the to the certificate authority
# @param ca_content the optional to content of the certificate authority
# @param puppetboard_hosts list of puppet board hosts
# @param tmpfs_stockpile_queue use a tmpfs for the file queue
# @param clean_stockpile aggressively delete the stockpile queue if it gets too big
# @param puppetdb_pass the puppetdb password
# @param puppetdb_ro_pass the puppetdb readonly password password
# @param log_level the loglevel to use
# @param facts_blacklist a list of facts to not store, useful for rejecting complex
#        large facts that change often
# @param facts_blacklist_type the type of items in the facts list either regex or literal
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
# @param ssldir the location of the ssldir
# @param ssl_verify_client how to validate mtls clients
# @param sites a list of additional nginx proxies to configure
#
class profile::puppetdb (
    Hash[String, Puppetmaster::Backends] $puppetmasters         = lookup('puppetmaster::servers'),
    Stdlib::Host                         $master                = lookup('profile::puppetdb::master'),
    String                               $jvm_opts              = lookup('profile::puppetdb::jvm_opts'),
    Boolean                              $elk_logging           = lookup('profile::puppetdb::elk_logging'),
    Stdlib::Unixpath                     $ca_path               = lookup('profile::puppetdb::ca_path'),
    Optional[String[1]]                  $ca_content            = lookup('profile::puppetdb::ca_content'),
    Array[Stdlib::Host]                  $puppetboard_hosts     = lookup('profile::puppetdb::puppetboard_hosts'),
    Boolean                              $tmpfs_stockpile_queue = lookup('profile::puppetdb::tmpfs_stockpile_queue'),
    Boolean                              $clean_stockpile       = lookup('profile::puppetdb::clean_stockpile'),
    String                               $puppetdb_pass         = lookup('puppetdb::password::rw'),
    String                               $puppetdb_ro_pass      = lookup('puppetdb::password::ro'),
    Optional[Stdlib::Host]               $db_ro_host            = lookup('profile::puppetdb::db_ro_host'),
    Puppetdb::Loglevel                   $log_level             = lookup('profile::puppetdb::log_level'),
    # TODO: rename to facts-blocklist when on 6.13.0 - T254646
    # https://puppet.com/docs/puppetdb/6/release_notes.html#puppetdb-6130
    Array[String]                        $facts_blacklist       = lookup('profile::puppetdb::facts_blacklist'),
    Enum['literal', 'regex']             $facts_blacklist_type  = lookup('profile::puppetdb::facts_blacklist_type'),
    Integer[0]                           $gc_interval           = lookup('profile::puppetdb::gc_interval'),
    Pattern[/\d+[dhms]/]                 $node_ttl              = lookup('profile::puppetdb::node_ttl'),
    Pattern[/\d+[dhms]/]                 $node_purge_ttl        = lookup('profile::puppetdb::node_purge_ttl'),
    Pattern[/\d+[dhms]/]                 $report_ttl            = lookup('profile::puppetdb::report_ttl'),
    Nginx::SSL::Verify_client            $ssl_verify_client     = lookup('profile::puppetdb::ssl_verify_client'),
    Hash[String[1], Hash]                $sites                 = lookup('profile::puppetdb::sites'),
    Optional[Stdlib::Unixpath]           $ssldir                = lookup('profile::puppetdb::ssldir'),
) {
    # Prometheus JMX agent for the Puppetdb's JVM
    $jmx_exporter_config_file = '/etc/puppetdb/jvm_prometheus_puppetdb_jmx_exporter.yaml'
    $prometheus_jmx_exporter_port = 9400
    $prometheus_listen_address = $facts['wmflib']['is_container'] ? {
                                    true  => '0.0.0.0',
                                    false => $facts['networking']['ip'],
                                }
    $prometheus_java_opts = "-javaagent:/usr/share/java/prometheus/jmx_prometheus_javaagent.jar=${prometheus_listen_address}:${prometheus_jmx_exporter_port}:${jmx_exporter_config_file}"

    # The JVM heap size has been raised to 6G for T170740
    class { 'puppetmaster::puppetdb':
        master                => $master,
        jvm_opts              => "${jvm_opts} ${prometheus_java_opts}",
        ssldir                => $ssldir,
        ca_path               => $ca_path,
        ca_content            => $ca_content,
        puppetdb_pass         => $puppetdb_pass,
        puppetdb_ro_pass      => $puppetdb_ro_pass,
        db_ro_host            => $db_ro_host,
        log_level             => $log_level,
        tmpfs_stockpile_queue => $tmpfs_stockpile_queue,
        facts_blacklist       => $facts_blacklist,
        facts_blacklist_type  => $facts_blacklist_type,
        gc_interval           => $gc_interval,
        node_ttl              => $node_ttl,
        node_purge_ttl        => $node_purge_ttl,
        report_ttl            => $report_ttl,
        ssl_verify_client     => $ssl_verify_client,
    }
    # TODO: remove this when a fix is in place T263578
    # This is quite a heavy hammer to work around on going issues
    # Currently the postgresql server is struggling to perform its auto vacuum
    # functions.  When this happens the stockpile queue starts to fill up.
    # This code will monitor that directory and delete all queued reports
    # when more then 1GB of space has been used.  Under normal operations
    # only about 0->100MB is more then enough space.
    # The result of this hack is that we will looses historical reports and fact
    # information which could affect cumin/puppetboard operations
    if $clean_stockpile {
        file { '/usr/local/bin/puppetdb_clean_stockpile':
            ensure => file,
            owner  => 'root',
            mode   => '0500',
            source => 'puppet:///modules/profile/puppetdb/clean_stockpile.sh',
        }
        systemd::timer::job { 'monitor_stockpile_queue':
            ensure      => 'present',
            user        => 'root',
            command     => '/usr/local/bin/puppetdb_clean_stockpile',
            description => 'Temporary job to clean out stockpile queue T263578',
            interval    => { 'start' => 'OnCalendar', 'interval' => '*:0/5' },  # every 5mins
        }
    }

    # Export JMX metrics to prometheus
    profile::prometheus::jmx_exporter { "puppetdb_${facts['networking']['hostname']}":
        hostname    => $facts['networking']['hostname'],
        port        => $prometheus_jmx_exporter_port,
        config_file => $jmx_exporter_config_file,
        source      => 'puppet:///modules/puppetdb/jvm_prometheus_puppetdb_jmx_exporter.yaml',
    }

    # Firewall rules

    # Only the TLS-terminating nginx proxy will be exposed
    $puppetmasters_ferm = inline_template('<%= @puppetmasters.values.flatten(1).map { |p| p[\'worker\'] }.sort.join(\' \')%>')

    ferm::service { 'puppetdb':
        proto   => 'tcp',
        port    => 443,
        notrack => true,
        srange  => "@resolve((${puppetmasters_ferm}))",
    }
    $puppetservers = wmflib::role::hosts('puppetserver')
    unless $puppetservers.empty() {
        ferm::service { 'puppetserveres access to puppetdb':
            proto   => 'tcp',
            port    => 443,
            notrack => true,
            srange  => $puppetservers,
        }
    }

    ferm::service { 'puppetdb-cumin':
        proto  => 'tcp',
        port   => 443,
        srange => '$CUMIN_MASTERS',
    }

    unless $puppetboard_hosts.empty {
        ferm::service { 'puppetboard':
            proto  => 'tcp',
            port   => 443,
            srange => "@resolve((${puppetboard_hosts.join(' ')}))",
        }
    }

    if $elk_logging {
        # Ship PuppetDB logs to ELK
        rsyslog::input::file { 'puppetdb':
            path => '/var/log/puppetdb/puppetdb.log',
        }
    }
    include profile::puppetdb::microservice
    ensure_packages(['python3-dateparser'])
    file { '/usr/local/bin/pdb-changes':
        ensure => file,
        mode   => '0555',
        source => 'puppet:///modules/profile/puppetdb/pdb_changes.py',
    }
    file { '/usr/local/bin/kernel_report':
        ensure => file,
        mode   => '0555',
        source => 'puppet:///modules/profile/puppetdb/kernel_report.py',
    }
    $sites.each |$site, $config| {
        profile::puppetdb::site { $site:
            * => $config,
        }
    }
}
