# = Define: elasticsearch::instance
#
# This class installs/configures/manages the elasticsearch service.
#
# == Parameters:
# - $cluster_name:  name of the cluster for this elasticsearch instance to join
#       never name your cluster "elasticsearch" because that is the default
#       and you don't want servers without any configuration to join your
#       cluster.
# - $version:  Version of elasticsearch to install and configure.
#       Either 5, 6 or 7.
# - $http_port: Port for elasticsearch to live on. Default: 9200
# - $transport_tcp_port: Port used for inter-node transport. Default: 9300
# - $node_name: Node name exposed within elasticsearch
#       Default: ${::hostname}-${title}
# - $base_data_dir: Where elasticsearch stores its data. Must be unique per-cluster.
#       Default: /srv/elasticsearch
# - $send_logs_to_logstash: When true logs are send to logstash. $logstash_host
#       must also be provided. Default: true.
# - $logstash_host: host to which logs will be sent. If `undef` no logs will be shipped.
# - $logstash_gelf_port: Port on $logstash_host accepting logs in gelf format.
# - $logstash_logback_port: Port on localhost accepting logs from log4j.
# - $logstash_transport: Logstash transport method. This can only be one of 'Gelf' or 'syslog'.
# - $heap_memory:   amount of memory to allocate to elasticsearch.  Defaults to
#       "2G".  Should be set to about half of ram or a 30G, whichever is
#       smaller.
# - $plugins_dir: value for path.plugins.  Defaults to /srv/deployment/elasticsearch/plugins.
# - $plugins_mandatory: list of mandatory plugins.  Defaults to undef.
# - $minimum_master_nodes:  how many master nodes must be online for this node
#       to believe that the Elasticsearch cluster is functioning correctly.
#       Defaults to 1.  Should be set to number of master eligible nodes in
#       cluster / 2 + 1.
# - $holds_data: should this node hold data?  Defaults to true.
# - $auto_create_index: should the cluster automatically create new indices?
#       Defaults to false.
# - $expected_nodes: after a full cluster restart the cluster will immediately
#       start after this many nodes rejoin.  Defaults to 1 but shouldn't stay
#       that way in production.  Should be set to the number of nodes in the
#       cluster.
# - $recover_after_nodes: after a full cluster restart once this many nodes
#       join the cluster it will wait $recover_after_time for this for
#       $expected_nodes to join.   If they don't it'll start anyway. Defaults to
#       1 but shouldn't stay that way in production.  Set this to however many
#       nodes would allow the cluster to limp along and continue working. Note
#       that if the cluster does come up without all the nodes it'll have to
#       create new replicas which is inefficient if the other node does come
#       back.
# - $recover_after_time: see $recover_after_nodes.  Defaults to a minute
#       because that feels like a decent amount of time to wait for the
#       remaining nodes to catch up.
# - $awareness_attributes: attributes used for allocation awareness, comma
#       separated.  Defaults to undef meaning none.
# - $row: row this node is on.  Can be used for allocation awareness.  Defaults
#       to undef meaning don't set it.
# - $rack: rack this node is on.  Can be used for allocation awareness.
#       Defaults to undef meaning don't set it.
# - $unicast_hosts: hosts to seed Elasticsearch's unicast discovery mechanism.
#       All master nodes must be listed here.
# - $bind_networks: networks to bind (both transport and http connectors)
#       see https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-network.html#network-interface-values
# - $publish_host: host to publish (both transport and http connectors)
#       see https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-network.html
# - $filter_cache_size: size of the filter cache.  See
#       www.elasticsearch.org/guide/en/elasticsearch/reference/current/index-modules-cache.html
#       for possible values.  Default is 10% like the Elasticsearch default.
# - $bulk_thread_pool_executors: number of executors for bulk actions on each
#       node.
# - $bulk_thread_pool_capacity: queue depth for bulk actions of each node.
# - $load_fixed_bitset_filters_eagerly: set to false to disable loading
#        bitsets in memory when opening indices will slowdown queries but can
#        significantly reduce heap usage.
# - $gc_log: set to true to activate garbage collection logs
#        Default: true
# - $search_shard_count_limit: Maximum number of indices that can be
#        queried in a single search request. Default: 1000.
# - $reindex_remote_whitelist: set to a comma delimited list of allowed remote
#        host and port combinations (e.g. otherhost:9243, another:9243,
#        127.0.10.*:9243, localhost:*). Scheme is ignored by the whitelist - only host
#        and port are used. Defaults to undef, which means no remote reindex can occur.
# - $script_max_compilations_per_minute: integer, max number of script
#        compilations per minute, defaults to undef (see T171579). (Deprecated)
#        TODO: Remove
# - $ltr_cache_size: string, Size of memory cache for LTR plugin.
# - $curator_uses_unicast_hosts: should curator try to connect to hosts
#        configured for unicast discovery or only to localhost. Curator
#        configuration allows to configure multiple hosts instead of just
#        localhost, which make sense for robustness. In some cases, we do not
#        want the API exposed outside of localhost, so using just localhost
#        is useful in those cases.
#        Default: true (use all hosts defined in unicast_hosts)
# - $tune_gc_new_size_ratio: Tune the GC to set a ratio between young and
#        old gen sizes. For example, a value of '3' means that the size of
#        the old generation will be 3 times the young generation. Depending
#        on the workload of your application it might be better to have a
#        bigger old gen (to avoid for example expensive and frequent full
#        GC runs) or a bigger young gen (for example if the majority of objects
#        created are short term or temporary).
# - $disktype: The type of physical storage backing this ES instance to be
#        used for index routing allocation. e.g. 'ssd', 'hdd'
# == Sample usage:
#
#   class { "elasticsearch":
#       cluster_name = 'labs-search'
#   }
#
define elasticsearch::instance(
    # the following parameters are injected by the main elasticsearch class
    String $cluster_name,
    String $version,
    Stdlib::Port $http_port,
    Stdlib::Port $transport_tcp_port,
    Stdlib::Absolutepath $base_data_dir,
    String $short_cluster_name,
    Optional[String] $logstash_host                          = undef,
    Optional[Stdlib::Port] $logstash_gelf_port               = 12201,
    Optional[Stdlib::Port] $logstash_logback_port            = 11514,
    Enum['Gelf', 'syslog'] $logstash_transport               = 'Gelf',
    Optional[String] $row                                    = undef,
    Optional[String] $rack                                   = undef,

    # the following parameters have defaults that are sane both for single
    # and multi-instances
    String $java_major_version                               = String($facts['java']['version']['major']),
    String $node_name                                        = "${::hostname}-${cluster_name}",
    Boolean $send_logs_to_logstash                           = true,
    String $heap_memory                                      = '2G',
    Stdlib::AbsolutePath $plugins_dir                        = '/usr/share/elasticsearch/plugins',
    Optional[Array[String]] $plugins_mandatory               = undef,
    Integer $minimum_master_nodes                            = 1,
    Boolean $holds_data                                      = true,
    Variant[Boolean, String] $auto_create_index              = false,
    Integer $expected_nodes                                  = 1,
    Integer $recover_after_nodes                             = 1,
    String $recover_after_time                               = '1s',
    Optional[String] $awareness_attributes                   = undef,
    Array[String] $unicast_hosts                             = [],
    Array[String] $bind_networks                             = ['_local_', '_site_'],
    String $publish_host                                     = $facts['ipaddress'],
    String $filter_cache_size                                = '10%',
    Optional[Integer] $bulk_thread_pool_executors            = undef,
    Optional[Integer] $bulk_thread_pool_capacity             = undef,
    Boolean $load_fixed_bitset_filters_eagerly               = true,
    Boolean $gc_log                                          = true,
    Integer $search_shard_count_limit                        = 1000,
    Optional[String] $reindex_remote_whitelist               = undef,
    Optional[Integer[0]] $script_max_compilations_per_minute = undef,
    Optional[String] $ltr_cache_size                         = undef,
    Boolean $curator_uses_unicast_hosts                      = true,
    Optional[Integer] $tune_gc_new_size_ratio                = undef,
    Optional[Enum['ssd','hdd']] $disktype                    = undef,
    Boolean $use_cms_gc                                      = false,
    Integer $cms_gc_init_occupancy_fraction                  = 75,

    # Dummy parameters consumed upstream of elasticsearch::instance,
    # but convenient to unify per-cluster configuration
    Optional[String] $certificate_name                       = undef,
    Array[String] $cluster_hosts                             = [],
    Optional[Stdlib::Port] $tls_port                         = undef,
    Optional[Stdlib::Port] $tls_ro_port                      = undef,
    Optional[Array[String]] $indices_to_monitor              = undef,
) {

    # Check arguments
    if $cluster_name == 'elasticsearch' {
        fail('$cluster_name must not be set to "elasticsearch"')
    }

    if $send_logs_to_logstash and $logstash_host == undef {
        fail('Need a logstash_host to send logs to logstash')
    }

    $master_eligible = $::fqdn in $unicast_hosts

    if $gc_log == true {
        $gc_log_flags = $java_major_version ? {
            '8'       => [
                "-Xloggc:/var/log/elasticsearch/${cluster_name}_jvm_gc.%p.log",
                '-XX:+PrintGCDetails',
                '-XX:+PrintGCDateStamps',
                '-XX:+PrintGCTimeStamps',
                '-XX:+PrintTenuringDistribution',
                '-XX:+PrintGCCause',
                '-XX:+PrintGCApplicationStoppedTime',
                '-XX:+UseGCLogFileRotation',
                '-XX:NumberOfGCLogFiles=10',
                '-XX:GCLogFileSize=20M',
            ],
            # the above GC flags are no longer valid as of Java 11, which is the default
            # Java for Debian 10 and 11.
            /(10|11)/ => [
                "-Xlog:gc*:file=/var/log/elasticsearch/${cluster_name}_jvm_gc.%p.log::filecount=10,filesize=20000",
                '-Xlog:gc+age=trace',
                '-Xlog:safepoint',
            ],
            default   => fail("Java version ${facts['java']['version']['major']} not supported"),
        }

    } else {
        $gc_log_flags = []
    }

    $gc_tune_flags = $tune_gc_new_size_ratio ? {
        default => ["-XX:NewRatio=${tune_gc_new_size_ratio}"],
        undef   => []
    }

    $gc_flags = $gc_log_flags + $gc_tune_flags

    $curator_hosts = $curator_uses_unicast_hosts ? {
        true    => concat($unicast_hosts, '127.0.0.1'),
        default => [ '127.0.0.1' ],
    }

    elasticsearch::curator::config { $cluster_name:
        ensure  => present,
        content => template('elasticsearch/curator_cluster.yaml.erb'),
    }

    # These are implied by the systemd unit
    $config_dir = "/etc/elasticsearch/${cluster_name}"
    $data_dir = "${base_data_dir}/${cluster_name}"

    file { $config_dir:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { "${config_dir}/elasticsearch.yml":
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        content => template("elasticsearch/elasticsearch_${version}.yml.erb"),
        mode    => '0444',
        require => Package['elasticsearch-oss'],
    }

    file { "${config_dir}/logging.yml":
        ensure => absent,
    }
    file { "${config_dir}/log4j2.properties":
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        content => template("elasticsearch/log4j2_${version}.properties.erb"),
        mode    => '0444',
        require => Package['elasticsearch-oss'],
    }
    file { "${config_dir}/jvm.options":
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        content => template('elasticsearch/jvm.options.erb'),
        mode    => '0444',
        require => Package['elasticsearch-oss'],
    }

    # elasticsearch refuses to start without the "scripts" directory, even if
    # we do not actually use any scripts.
    file { "${config_dir}/scripts":
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package['elasticsearch-oss'],
    }

    $ensure_keystore = $version ? {
        '5'     => 'absent',
        default => 'present'
    }

    if $ensure_keystore == 'present' {
        exec { "elasticsearch-create-keystore-${title}":
            command     => '/usr/share/elasticsearch/bin/elasticsearch-keystore create',
            environment => ["ES_PATH_CONF=${config_dir}"],
            creates     => "${config_dir}/elasticsearch.keystore",
            require     => Package['elasticsearch-oss'],
            before      => File["${config_dir}/elasticsearch.keystore"],
        }
    }

    file { "${config_dir}/elasticsearch.keystore":
            ensure => $ensure_keystore,
            owner  => 'root',
            group  => 'elasticsearch',
            mode   => '0640',
    }

    file { $data_dir:
      ensure  => directory,
      owner   => 'elasticsearch',
      group   => 'elasticsearch',
      mode    => '0755',
      require => Package['elasticsearch-oss'],
    }
    # GC logs rotation is done by the JVM, but on JVM restart, the logs left by
    # the previous instance are left alone. This systemd timer takes care of cleaning up
    # GC logs older than 30 days.
    $gc_cleanup_job_title = "elasticsearch-${title}-gc-log-cleanup"

    systemd::timer::job { $gc_cleanup_job_title:
        ensure      => present,
        user        => 'root',
        description => 'Cleanup GC logs',
        command     => "/usr/bin/find /var/log/elasticsearch -name '${cluster_name}_jvm_gc.*.log*' -mtime +30 -delete",
        interval    => {'start' => 'OnCalendar', 'interval' => '*-*-* 02:12:00'},
    }

    systemd::tmpfile {"elasticsearch-${cluster_name}":
        ensure  => present,
        content => "d    /var/run/elasticsearch-${cluster_name}  0755 elasticsearch elasticsearch - -",
    }

    # Note that we don't notify the Elasticsearch service of changes to its
    # config files because you need to be somewhat careful when restarting it.
    # So, for now at least, we'll be restarting it manually.
    # As a further countermeasure, tell puppet to run a noop instead of restarting
    service { "elasticsearch_${version}@${cluster_name}":
        ensure     => running,
        provider   => 'systemd',
        enable     => true,
        hasrestart => false,
        restart    => '/bin/true',
        tag        => 'elasticsearch_services',
        require    => [
            Package['elasticsearch-oss'],
            Systemd::Unit["elasticsearch_${version}@.service"],
            File["${config_dir}/elasticsearch.yml"],
            File["${config_dir}/logging.yml"],
            File["${config_dir}/log4j2.properties"],
            File["${config_dir}/jvm.options"],
            File[$data_dir],
        ],
    }
}
