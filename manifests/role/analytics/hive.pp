# role/analytics/hive.pp
#
# Role classes for Analytics Hive client and server nodes.
# These role classes will configure Hive properly in either
# Labs or Production environments.
#
# If you are using these in Labs, you must include role::analytics::hive::server
# on your primary Hadoop NameNode.
#
# role::analytics::hive::client requires role::analytics::hadoop::client,
# and will install Hadoop client pacakges and configs.  In Labs,
# you must set appropriate Hadoop client global parameters.  See
# role/analytics/hadoop.pp documentation for more info.


# == Class role::analytics::hive::config
#
class role::analytics::hive::config {
    # require zookeeper config to get zookeeper hosts array.
    include role::analytics::hadoop::config

    # Set this pretty high, to avoid limiting the number
    # of substitutionvariables a Hive script can use.
    $variable_substitute_depth = 10000

    # The WMF webrequest table uses HCatalog's JSON Serde.
    # Automatically include this in Hive client classpaths.
    $hcatalog_jar = 'file:///usr/lib/hive-hcatalog/share/hcatalog/hive-hcatalog-core.jar'

    # If refinery is included on this node, then add
    # refinery-hive.jar to the auxpath as well
    if defined(Class['role::analytics::refinery']) {
        $auxpath = "${hcatalog_jar},file://${::role::analytics::refinery::path}/artifacts/refinery-hive.jar"
    }
    else {
        $auxpath = $hcatalog_jar
    }

    # Hive uses Zookeeper for table locking.
    $zookeeper_hosts = keys(hiera('zookeeper_hosts'))

    # We set support concurrency to false by default.
    # if someone needs to use it in their hive job, they
    # may manually set it to true via
    # set hive.support.concurrency = true;
    $support_concurrency = false

    if $::realm == 'production' {
        include passwords::analytics

        $server_host     = 'analytics1027.eqiad.wmnet'
        $metastore_host  = 'analytics1027.eqiad.wmnet'
        $jdbc_password   = $passwords::analytics::hive_jdbc_password
    }
    elsif $::realm == 'labs' {
        $server_host     = $role::analytics::hadoop::config::namenode_hosts[0]
        $metastore_host  = $role::analytics::hadoop::config::namenode_hosts[0]
        $jdbc_password   = 'hive'
    }
}


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


# == Class role::analytics::hive::server
# Sets up Hive Server2 and MySQL backed Hive Metastore.
#
class role::analytics::hive::server inherits role::analytics::hive::client {
    if (!defined(Package['mysql-server'])) {
        package { 'mysql-server':
            ensure => 'installed',
        }
    }

    # Make sure mysql-server is installed before
    # MySQL Hive Metastore database class is applied.
    Package['mysql-server'] -> Class['cdh::hive::metastore::mysql']

    # Setup Hive server and Metastore
    class { 'cdh::hive::master':
        heapsize => '512',
    }
}
