# SPDX-License-Identifier: Apache-2.0
# There are additional parameters to opensearch::instance that
# are not mentioned here. Those are not to be set per-instance and
# instead are globaly set and flow from the opensearch class.
type Opensearch::InstanceParams = Struct[{
    # the following parameters are injected by the main opensearch class
    'cluster_name'       => Optional[String],
    'http_port'          => Optional[Stdlib::Port],
    'transport_tcp_port' => Optional[Stdlib::Port],

    # the following parameters need specific default values for single instance
    'node_name'        => Optional[String],

    # the following parameters have defaults that are sane both for single
    # and multi-instances
    'heap_memory'                        => Optional[String],
    'plugins_dir'                        => Optional[Stdlib::Absolutepath],
    'plugins_mandatory'                  => Optional[Array[String]],
    'minimum_master_nodes'               => Optional[Integer],
    'holds_data'                         => Optional[Boolean],
    'auto_create_index'                  => Optional[Variant[Boolean, String]],
    'expected_nodes'                     => Optional[Integer],
    'recover_after_nodes'                => Optional[Integer],
    'recover_after_time'                 => Optional[String],
    'awareness_attributes'               => Optional[String],
    'unicast_hosts'                      => Optional[Array[String]],
    'bind_networks'                      => Optional[Array[String]],
    'publish_host'                       => Optional[String],
    'filter_cache_size'                  => Optional[String],
    'bulk_thread_pool_executors'         => Optional[Integer],
    'bulk_thread_pool_capacity'          => Optional[Integer],
    'load_fixed_bitset_filters_eagerly'  => Optional[Boolean],
    'gc_log'                             => Optional[Boolean],
    'search_shard_count_limit'           => Optional[Integer],
    'reindex_remote_whitelist'           => Optional[String],
    # TODO: remove
    'script_max_compilations_per_minute' => Optional[Integer[0]],
    'ltr_cache_size'                     => Optional[String],
    'curator_uses_unicast_hosts'         => Optional[Boolean],
    'send_logs_to_logstash'              => Optional[Boolean],
    'tune_gc_new_size_ratio'             => Optional[Integer],
    'disktype'                           => Optional[Enum['ssd','hdd']],
    'use_cms_gc'                         => Optional[Boolean],
    'cms_gc_init_occupancy_fraction'     => Optional[Integer],
    'watermarks'                         => Optional[Hash],
    'compatibility_mode'                 => Optional[Boolean],
    'disable_security_plugin'            => Optional[Boolean],

    # Dummy parameters consumed upstream of opensearch::instance,
    # but convenient to declare per-cluster
    'certificate_name'   => Optional[String],
    'cluster_hosts'      => Optional[Array[String]],
    'tls_port'           => Optional[Stdlib::Port],
    'tls_ro_port'        => Optional[Stdlib::Port],
    'short_cluster_name' => Optional[String],
    'indices_to_monitor' => Optional[Array[String]],
}]
