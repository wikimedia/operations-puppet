# == Class profile::hive::client
# Installs base configs and packages for hive client nodes.
#
# filtertags: labs-project-analytics labs-project-math
class profile::hive::client(
    $zookeeper_clusters     = hiera('zookeeper_clusters'),
    $zookeeper_cluster_name = hiera('profile::hive::client::zookeeper_cluster_name'),
    $hiveserver_host        = hiera('profile::hive::client::server_host'),
    $hiveserver_port        = hiera('profile::hive::client::server_port'),
    $metastore_host         = hiera('profile::hive::client::hive_metastore_host'),
    $hive_server_opts       = hiera('profile::hive::client::hive_server_opts', undef),
    $hive_metastore_opts    = hiera('profile::hive::client::hive_metastore_opts', undef),
    $java_home              = hiera('profile::hive::client::java_home', undef),
) {
    require ::profile::hadoop::common

    # The WMF webrequest table uses HCatalog's JSON Serde.
    # Automatically include this in Hive client classpaths.
    $hcatalog_jar = 'file:///usr/lib/hive-hcatalog/share/hcatalog/hive-hcatalog-core.jar'
    $auxpath = $hcatalog_jar
    $zookeeper_hosts        = keys($zookeeper_clusters[$zookeeper_cluster_name]['hosts'])

    # You must set at least:
    #   metastore_host
    class { '::cdh::hive':
        # Hive uses Zookeeper for table locking.
        zookeeper_hosts           => $zookeeper_hosts,
        # We set support concurrency to false by default.
        # if someone needs to use it in their hive job, they
        # may manually set it to true via
        # set hive.support.concurrency = true;
        support_concurrency       => false,
        # Set this pretty high, to avoid limiting the number
        # of substitution variables a Hive script can use.
        variable_substitute_depth => 10000,
        auxpath                   => $auxpath,
        # default to using Snappy for parquet formatted tables
        parquet_compression       => 'SNAPPY',
        hive_server_opts          => $hive_server_opts,
        hive_metastore_opts       => $hive_metastore_opts,
        metastore_host            => $metastore_host,
        java_home                 => $java_home,
    }

    # Set up a wrapper script for beeline, the command line
    # interface to HiveServer2 and install it at
    # /usr/local/bin/beeline

    file { '/usr/local/bin/beeline':
        content => template('role/analytics_cluster/hive/beeline_wrapper.py.erb'),
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
    }
}
