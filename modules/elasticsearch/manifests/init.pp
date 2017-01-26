# = Class: elasticsearch
#
# This class installs/configures/manages the elasticsearch service.
#
# == Parameters:
# - $cluster_name:  name of the cluster for this elasticsearch instance to join
#       never name your cluster "elasticsearch" because that is the default
#       and you don't want servers without any configuration to join your
#       cluster.
# - $heap_memory:   amount of memory to allocate to elasticsearch.  Defaults to
#       "2G".  Should be set to about half of ram or a 30G, whichever is
#       smaller.
# - $multicast_group:  multicast group to use for peer discovery.  Defaults to
#       elasticsearch's default: '224.2.2.4'.
# - $data_dir: Where elasticsearch stores its data. We want to move this to
#       /srv/elasticsearch for new deployments.
#       Default: /var/lib/elasticsearch
# - $plugins_dir: value for path.plugins.  Defaults to /srv/deployment/elasticsearch/plugins.
# - $plugins_mandatory: list of mandatory plugins.  Defaults to undef.
# - $minimum_master_nodes:  how many master nodes must be online for this node
#       to believe that the Elasticsearch cluster is functioning correctly.
#       Defaults to 1.  Should be set to number of master eligible nodes in
#       cluster / 2 + 1.
# - $master_eligible:  is this node eligible to be a master node?  Defaults to
#       true.
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
# - $multicast_enabled: Should multicast be enabled. See
#       https://www.elastic.co/guide/en/elasticsearch/reference/1.7/modules-discovery-zen.html
#       for more documentation.
#       Note: It make sense to have multicast configuration separated from
#       unicast. It is valid to have both unicast and multicast enabled at the
#       same time and can be useful as a transition state.
#       Defaults to 'false'
# - $unicast_hosts: hosts to seed Elasticsearch's unicast discovery mechanism.
#       In an environment without reliable multicast (OpenStack) add all the
#       hosts in the cluster to this list.  Elasticsearch will still use
#       multicast discovery but this will keep it from getting lost if none of
#       its pings reach other servers.
# - $bind_networks: networks to bind (both transport and http connectors)
#       see https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-network.html#network-interface-values
# - $publish_host: host to publish (both transport and http connectors)
#       see https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-network.html
# - $filter_cache_size: size of the filter cache.  See
#       www.elasticsearch.org/guide/en/elasticsearch/reference/current/index-modules-cache.html
#       for possible values.  Default is 10% like the Elasticsearch default.
# - $bulk_thread_pool_capacity: queue depth for bulk actions of each node.
# - $bulk_thread_pool_executors: number of executors for bulk actions on each
#       node.
# - $statsd_host: host to send statsd data to
# - $merge_threads: Number of merge threads to use. Default 3. Set
#        to 1 if using spinning disks.
# - $load_fixed_bitset_filters_eagerly: set to false to disable loading
#        bitsets in memory when opening indices will slowdown queries but can
#        significantly reduce heap usage.
# - $gelf_hosts: array of hosts to which logs will be sent. Can be either a hostname
#        or an array of hostnames. In the later case, one is choosen at random.
#        If `undef` no logs will be shipped.
# - $gelf_port: port on which the logs will be sent
# - $gc_log: set to true to activate garbage collection logs
#        Default: true
#
# == Sample usage:
#
#   class { "elasticsearch":
#       cluster_name = 'labs-search'
#   }
#
class elasticsearch(
    $cluster_name,
    $heap_memory = '2G',
    $multicast_group = '224.2.2.4',
    $data_dir = '/var/lib/elasticsearch',
    $plugins_dir = '/srv/deployment/elasticsearch/plugins',
    $plugins_mandatory = undef,
    $minimum_master_nodes = 1,
    $master_eligible = true,
    $holds_data = true,
    $auto_create_index = false,
    $expected_nodes = 1,
    $recover_after_nodes = 1,
    $recover_after_time = '1s',
    $awareness_attributes = undef,
    $row = undef,
    $rack = undef,
    $multicast_enabled = false,
    $unicast_hosts = undef,
    $bind_networks = ['_local_', '_site_'],
    $publish_host = '_eth0_',
    $filter_cache_size = '10%',
    $bulk_thread_pool_executors = undef,
    $bulk_thread_pool_capacity = undef,
    $statsd_host = undef,
    $merge_threads = 3,
    $load_fixed_bitset_filters_eagerly = true,
    $graylog_hosts = undef,
    $graylog_port = 12201,
    $gc_log = true,
    $java_package = 'openjdk-8-jdk',
) {

    # Check arguments
    if $cluster_name == 'elasticsearch' {
        fail('$cluster_name must not be set to "elasticsearch"')
    }

    validate_bool($multicast_enabled)
    validate_bool($gc_log)

    # if no graylog_host is given, do not send logs
    $send_logs_to_logstash = is_array($graylog_hosts)

    if $send_logs_to_logstash {
        validate_array($graylog_hosts)
        $rotated_graylog_host = fqdn_rotate($graylog_hosts, $::hostname)
        $graylog_host = $rotated_graylog_host[0]
        validate_string($graylog_host)
        # validate_integer($graylog_port)  // should be uncommented when we upgrade to stdlib 4.x
    }

    $gc_log_flags = $gc_log ? {
        true    => [
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
        default => [],
    }

    class { '::elasticsearch::packages':
        java_package => $java_package,
    }

    file { '/etc/elasticsearch/elasticsearch.yml':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        content => template('elasticsearch/elasticsearch.yml.erb'),
        mode    => '0444',
        require => Package['elasticsearch'],
    }
    file { '/etc/elasticsearch/logging.yml':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        content => template('elasticsearch/logging.yml.erb'),
        mode    => '0444',
        require => Package['elasticsearch'],
    }
    # elasticsearch refuses to start without the "scripts" directory, even if
    # do not actually use any scripts.
    file { '/etc/elasticsearch/scripts':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package['elasticsearch'],
    }
    file { '/etc/default/elasticsearch':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        content => template('elasticsearch/elasticsearch.erb'),
        mode    => '0444',
        require => Package['elasticsearch'],
    }
    file { '/etc/logrotate.d/elasticsearch':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/elasticsearch/logrotate',
    }
    # GC logs rotation is done by the JVM, but on JVM restart, the logs left by
    # the previous instance are left alone. This cron takes care of cleaning up
    # GC logs older than 30 days.
    cron { 'elasticsearch-gc-log-cleanup':
        ensure  => present,
        minute  => 12,
        hour    => 2,
        command => "find /var/log/elasticsearch -name '${cluster_name}_jvm_gc.*.log*' -mtime +30 -delete",
    }
    # Note that we don't notify the Elasticsearch service of changes to its
    # config files because you need to be somewhat careful when restarting it.
    # So, for now at least, we'll be restarting it manually.

    # Keep service running
    service { 'elasticsearch':
        ensure  => running,
        enable  => true,
        require => [
            Package['elasticsearch'],
            File['/etc/elasticsearch/elasticsearch.yml'],
            File['/etc/elasticsearch/logging.yml'],
            File['/etc/default/elasticsearch'],
        ],
    }

    # Make sure that some pesky, misleading log files aren't kept around
    # These files are created when the server is using the default cluster_name
    # and are never written to when the server is using the correct cluster name
    # thus leaving old files with no useful information named in such a way that
    # someone might think they contain useful logs.
    file { '/var/log/elasticsearch/elasticsearch.log':
        ensure => absent,
    }
    file { '/var/log/elasticsearch/elasticsearch_index_indexing_slowlog.log':
        ensure => absent,
    }
    file { '/var/log/elasticsearch/elasticsearch_index_search_slowlog.log':
        ensure => absent,
    }

    # Cluster management tool, trusty only
    if os_version('ubuntu >= trusty') {
        file { '/usr/local/bin/es-tool':
            ensure  => file,
            owner   => 'root',
            group   => 'root',
            mode    => '0755',
            source  => 'puppet:///modules/elasticsearch/es-tool',
            require => [Package['python-elasticsearch'], Package['python-ipaddr']],
        }
    }
}
