class cassandra::defaults {
    $seeds                            = pick($::cassandra_seeds,                            [$::ipaddress])
    $cluster_name                     = pick($::cassandra_cluster_name,                     'Test Cluster')
    $num_tokens                       = pick($::cassandra_num_tokens,                       256)
    $authenticator                    = pick($::cassandra_authenticator,                    true)
    $authorizor                       = pick($::cassandra_authorizor,                       true)
    $data_file_directories            = pick($::cassandra_data_file_directories,            ['/var/lib/cassandra/data'])
    $commitlog_directory              = pick($::cassandra_commitlog_directory,              '/var/lib/cassandra/commitlog')
    $disk_failure_policy              = pick($::cassandra_disk_failure_policy,              'stop')
    $row_cache_size_in_mb             = pick($::cassandra_row_cache_size_in_mb,             200)
    $memory_allocator                 = pick($::cassandra_memory_allocator,                 'JEMallocAllocator')
    $saved_caches_directory           = pick($::cassandra_saved_caches_directory,           '/var/lib/cassandra/saved_caches')
    $concurrent_reads                 = pick($::cassandra_concurrent_reads,                 32)
    $concurrent_writes                = pick($::cassandra_concurrent_writes,                32)
    $concurrent_counter_writes        = pick($::cassandra_concurrent_counter_writes,        32)
    $storage_port                     = pick($::cassandra_storage_port,                     7000)
    $listen_address                   = pick($::cassandra_listen_address,                   $::ipaddress)

    # Since the default here is undef, we can't use stdlib's pick().
    $broadcast_address                = $::cassandra_broadcast_address ? {
        undef   => undef,
        default => $::cassandra_broadcast_address,
    }

    $start_native_transport           = pick($::cassandra_start_native_transport,           'true')
    $native_transport_port            = pick($::cassandra_native_transport_port,            9042)
    $start_rpc                        = pick($::cassandra_start_rpc,                        'true')
    $rpc_address                      = pick($::cassandra_rpc_address,                      $::ipaddress)
    $rpc_port                         = pick($::cassandra_rpc_port,                         9160)
    $rpc_server_type                  = pick($::cassandra_rpc_server_type,                  'sync')
    $incremental_backups              = pick($::cassandra_incremental_backups,              'false')
    $snapshot_before_compaction       = pick($::cassandra_snapshot_before_compaction,       'false')
    $auto_snapshot                    = pick($::cassandra_auto_snapshot,                    'true')
    $compaction_throughput_mb_per_sec = pick($::cassandra_compaction_throughput_mb_per_sec, 16)
    $endpoint_snitch                  = pick($::cassandra_endpoint_snitch,                  'GossipingPropertyFileSnitch')
    $internode_compression            = pick($::cassandra_internode_compression,            'all')

    # Since the default here is undef, we can't use stdlib's pick().
    $max_heap_size = $::cassandra_max_heap_size ? {
        undef      => undef,
        default    => $::cassandra_max_heap_size,
    }
    $heap_newsize  = $::cassandra_heap_newsize ? {
        undef      => undef,
        default    => $::cassandra_heap_newsize,
    }

    $jmx_port                         = pick($::cassandra_jmx_port,                          7199)
    # Since the default here is an empty array we can't use stdlib's pick().
    $additional_jvm_opts = $::cassandra_additional_jvm_opts ? {
        undef   => [],
        default => $::cassandra_additional_jvm_opts,
    }
    $dc                               = pick($::cassandra_dc,                               'datacenter1')
    $rack                             = pick($::cassandra_rack,                             'rack1')

    $yaml_template                    = pick($::cassandra_yaml_template,                    "${module}/cassandra.yaml.erb")
    $env_template                     = pick($::cassandra_env_template,                     "${module}/cassandra-env.sh.erb")
    $rackdc_template                  = pick($::cassandra_rackdc_template,                  "${module}/cassandra-rackdc.properties.erb")
}
