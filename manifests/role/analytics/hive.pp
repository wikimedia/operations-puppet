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
    # of substitution variables a Hive script can use.
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

        $jdbc_password   = $passwords::analytics::hive_jdbc_password
        # Must set hive_server_host and hive_metastore_host in hiera
        # in production.
        $default_hive_host = undef
    }
    elsif $::realm == 'labs' {
        $jdbc_password   = 'hive'
        # Default to hosting hive-server and hive-metastore on
        # primary namenode in labs.
        $default_hive_host = $role::analytics::hadoop::config::namenode_hosts[0]
    }

    $server_host     = hiera('hive_server_host', $default_hive_host)
    $metastore_host  = hiera('hive_metastore_host', $default_hive_host)
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
    if $::realm == 'labs' {
        require_package('mysql-server')
    }
    # Prod requires that this node also runs the analytics meta mysql instance.
    else {
        Class['role::analytics::mysql::meta'] -> Class['role::analytics::hive::server']
    }

    # TODO: Set these better once hive is on its own server.
    # See: https://phabricator.wikimedia.org/T110090
    # http://www.cloudera.com/content/www/en-us/documentation/enterprise/latest/topics/cdh_ig_hive_install.html#concept_alp_4kl_3q_unique_1
    # TODO: Use hiera.
    $server_heapsize = $::realm ? {
        'production' => 1024,
        default      => undef,
    }
    $metastore_heapsize = $::realm ? {
        'production' => 256,
        default      => undef,
    }
    # Setup Hive server and Metastore
    class { 'cdh::hive::master':
        server_heapsize    => $server_heapsize,
        metastore_heapsize => $metastore_heapsize,
    }

    ferm::service{ 'hive_server':
        proto  => 'tcp',
        port   => '10000',
        srange => '$INTERNAL',
    }

    ferm::service{ 'hive_metastore':
        proto  => 'tcp',
        port   => '9083',
        srange => '$INTERNAL',
    }
}
