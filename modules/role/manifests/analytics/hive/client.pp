# == Class role::analytics::hive
# Installs base configs for hive client nodes
#
class role::analytics::hive::client inherits role::analytics::hive::config {
    require role::analytics::hadoop::client

    class { '::cdh::hive':
        metastore_host            => $metastore_host,
        jdbc_password             => $jdbc_password,
        zookeeper_hosts           => $zookeeper_hosts,
        support_concurrency       => $support_concurrency,
        variable_substitute_depth => $variable_substitute_depth,
        auxpath                   => $auxpath,
        # default to using Snappy for parquet formatted tables
        parquet_compression       => 'SNAPPY',
    }
}
