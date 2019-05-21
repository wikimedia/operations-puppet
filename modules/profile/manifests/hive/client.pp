# == Class profile::hive::client
# Installs base configs and packages for hive client nodes.
#
# filtertags: labs-project-analytics labs-project-math
class profile::hive::client(
    $zookeeper_clusters                             = hiera('zookeeper_clusters'),
    $hiveserver_host                                = hiera('profile::hive::client::server_host'),
    $hiveserver_port                                = hiera('profile::hive::client::server_port'),
    $metastore_host                                 = hiera('profile::hive::client::hive_metastore_host'),
    $zookeeper_cluster_name                         = hiera('profile::hive::client::zookeeper_cluster_name', undef),
    $hive_server_opts                               = hiera('profile::hive::client::hive_server_opts', undef),
    $hive_metastore_opts                            = hiera('profile::hive::client::hive_metastore_opts', undef),
    $ensure_hive_site_in_hdfs                       = hiera('profile::hive::client::ensure_hive_site_in_hdfs', false),
    $java_home                                      = hiera('profile::hive::client::java_home', '/usr/lib/jvm/java-8-openjdk-amd64/jre'),
    $hive_metastore_sasl_enabled                    = hiera('profile::hive::client::hive_metastore_sasl_enabled', undef),
    $hive_metastore_kerberos_keytab_file            = hiera('profile::hive::client::hive_metastore_kerberos_keytab_file', undef),
    $hive_metastore_kerberos_principal              = hiera('profile::hive::client::hive_metastore_kerberos_principal', undef),
    $hive_server2_authentication                    = hiera('profile::hive::client::hive_server2_authentication', undef),
    $hive_server2_authentication_kerberos_principal = hiera('profile::hive::client::hive_server2_authentication_kerberos_principal', undef),
    $hive_server2_authentication_kerberos_keytab    = hiera('profile::hive::client::hive_server2_authentication_kerberos_keytab', undef),
    $hive_metastore_jdbc_user                       = hiera('profile::hive::client::hive_metastore_jdbc_user', undef),
    $hive_metastore_jdbc_password                   = hiera('profile::hive::client::hive_metastore_jdbc_password', undef),
    $hive_metastore_database                        = hiera('profile::hive::client::hive_metastore_jdbc_database', undef),
    $config_files_group_ownership                   = hiera('profile::hive::client::config_files_group_ownership', 'hdfs'),
) {
    require ::profile::hadoop::common

    # The WMF webrequest table uses HCatalog's JSON Serde.
    # Automatically include this in Hive client classpaths.
    $hcatalog_jar = 'file:///usr/lib/hive-hcatalog/share/hcatalog/hive-hcatalog-core.jar'
    $auxpath = $hcatalog_jar

    # If given a $zookeeper_cluster_name to use for query locking,
    # look up the hosts from $zookeeper_clusters.
    $zookeeper_hosts = $zookeeper_cluster_name ? {
        undef   => undef,
        default => keys($zookeeper_clusters[$zookeeper_cluster_name]['hosts']),
    }

    # You must set at least:
    #   metastore_host
    class { '::cdh::hive':
        # Hive uses Zookeeper for table locking.
        zookeeper_hosts                                => $zookeeper_hosts,
        # We set support concurrency to false by default.
        # if someone needs to use it in their hive job, they
        # may manually set it to true via
        # set hive.support.concurrency = true;
        support_concurrency                            => false,
        # Set this pretty high, to avoid limiting the number
        # of substitution variables a Hive script can use.
        variable_substitute_depth                      => 10000,
        auxpath                                        => $auxpath,
        # default to using Snappy for parquet formatted tables
        parquet_compression                            => 'SNAPPY',
        hive_server_opts                               => $hive_server_opts,
        hive_metastore_opts                            => $hive_metastore_opts,
        metastore_host                                 => $metastore_host,
        java_home                                      => $java_home,
        # Precaution for CVE-2018-1284
        hive_server_udf_blacklist                      => 'xpath,xpath_string,xpath_boolean,xpath_number,xpath_double,xpath_float,xpath_long,xpath_int,xpath_short',

        # Optional security configs
        hive_metastore_sasl_enabled                    => $hive_metastore_sasl_enabled,
        hive_metastore_kerberos_keytab_file            => $hive_metastore_kerberos_keytab_file,
        hive_metastore_kerberos_principal              => $hive_metastore_kerberos_principal,
        hive_server2_authentication                    => $hive_server2_authentication,
        hive_server2_authentication_kerberos_principal => $hive_server2_authentication_kerberos_principal,
        hive_server2_authentication_kerberos_keytab    => $hive_server2_authentication_kerberos_keytab,
        jdbc_username                                  => $hive_metastore_jdbc_user,
        jdbc_password                                  => $hive_metastore_jdbc_password,
        jdbc_database                                  => $hive_metastore_database,
        config_files_group_ownership                   => $config_files_group_ownership,
    }

    # Set up a wrapper script for beeline, the command line
    # interface to HiveServer2 and install it at
    # /usr/local/bin/beeline

    file { '/usr/local/bin/beeline':
        content => template('profile/hive/client/beeline_wrapper.py.erb'),
        mode    => '0755',
        owner   => 'root',
        group   => 'root',
    }

    # We need hive-site.xml in HDFS.  This can be included
    # on any node with a Hive client, but we really only
    # want to include it in one place.  Set the
    # profile::hive::client::ensure_hive_site_in_hdfs for only one node please!
    if $ensure_hive_site_in_hdfs {
        include ::profile::hive::site_hdfs
    }

}
