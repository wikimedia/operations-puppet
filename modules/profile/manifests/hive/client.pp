# SPDX-License-Identifier: Apache-2.0
# == Class profile::hive::client
# Installs base configs and packages for hive client nodes.
#
class profile::hive::client(
    Hash[String, Any] $zookeeper_clusters          = lookup('zookeeper_clusters'),
    Hash[String, Any] $hive_services               = lookup('hive_services'),
    String $hive_service_name                      = lookup('profile::hive::client::hive_service_name'),
    Optional[String] $config_files_group_ownership = lookup('profile::hive::client::config_files_group_ownership', { 'default_value' => undef }),
    Optional[String] $hive_metastore_jdbc_password = lookup('profile::hive::client::hive_metastore_jdbc_password', { 'default_value' => undef }),
    Boolean $deploy_jdbc_settings                  = lookup('profile::hive::client::deploy_jdbc_settings', { 'default_value' => false }),
    Integer[1,2] $hive_log4j_version               = lookup('profile::hive::client::log4j_version', default_value => 2),
    Optional[Stdlib::Host] $hive_metastore_host    = lookup('profile::hive::client::hive_metastore_host', { 'default_value' => undef }),
) {
    require ::profile::hadoop::common

    $hiveserver_host = $hive_services[$hive_service_name]['server_host']
    $hiveserver_port = $hive_services[$hive_service_name]['server_port']

    # In a multi-metastore setup, we want to force the hive server to use the
    # metastore co-located rather than the one referenced by the metastore_host
    # variable, since it could be a DNS CNAME. Example:
    #
    # analytics-hive.eqiad.wmnet -> resolves to -> an-coord1003
    #
    # If we have a metastore on an-coord1004, and metastore_host=analytics-hive.eqiad.wmnet,
    # then the hive server on the same node would point to the metastore on 1001.
    # This would work but then if an-coord1003 went down, the failover of the DNS CNAME
    # wouldn't be enough, since the hive server on 1002 would still point to the metastore
    # on 1001 (and a restart would be needed to pick up the new settings).
    $metastore_host = $hive_metastore_host ? {
        undef   => $hive_services[$hive_service_name]['metastore_host'],
        default => $hive_metastore_host,
    }

    $zookeeper_cluster_name = $hive_services[$hive_service_name]['zookeeper_cluster_name']
    $hive_server_opts = $hive_services[$hive_service_name]['server_opts']
    $hive_metastore_opts = $hive_services[$hive_service_name]['metastore_opts']
    $java_home = $hive_services[$hive_service_name]['java_home']
    $hive_metastore_sasl_enabled = $hive_services[$hive_service_name]['metastore_sasl_enabled']
    $hive_metastore_kerberos_keytab_file = $hive_services[$hive_service_name]['metastore_kerberos_keytab_file']
    $hive_metastore_kerberos_principal = $hive_services[$hive_service_name]['metastore_kerberos_principal']
    $hive_server2_authentication = $hive_services[$hive_service_name]['server_authentication']
    $hive_server2_authentication_kerberos_principal = $hive_services[$hive_service_name]['server_authentication_kerberos_principal']
    $hive_server2_authentication_kerberos_keytab = $hive_services[$hive_service_name]['server_authentication_kerberos_keytab']
    $hive_metastore_jdbc_host = $hive_services[$hive_service_name]['metastore_jdbc_host']
    $hive_metastore_jdbc_port = $hive_services[$hive_service_name]['metastore_jdbc_port']
    $hive_metastore_jdbc_user = $hive_services[$hive_service_name]['metastore_jdbc_user']
    $hive_metastore_database = $hive_services[$hive_service_name]['metastore_jdbc_database']
    $hive_cluster_delegation_token_store_class = $hive_services[$hive_service_name]['hive_cluster_delegation_token_store_class'] ? {
        undef   => 'org.apache.hadoop.hive.thrift.DBTokenStore',
        default => $hive_services[$hive_service_name]['hive_cluster_delegation_token_store_class'],
    }
    $hive_metastore_disallow_incompatible_col_type_changes = $hive_services[$hive_service_name]['hive_metastore_disallow_incompatible_col_type_changes'] ? {
        undef   => undef,
        default => $hive_services[$hive_service_name]['hive_metastore_disallow_incompatible_col_type_changes'],
    }

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
    class { '::bigtop::hive':
        # Hive uses Zookeeper for table locking.
        zookeeper_hosts                                       => $zookeeper_hosts,
        # We set support concurrency to false by default.
        # if someone needs to use it in their hive job, they
        # may manually set it to true via
        # set hive.support.concurrency = true;
        support_concurrency                                   => false,
        # Set this pretty high, to avoid limiting the number
        # of substitution variables a Hive script can use.
        variable_substitute_depth                             => 10000,
        auxpath                                               => $auxpath,
        # default to using Snappy for parquet formatted tables
        parquet_compression                                   => 'SNAPPY',
        hive_server_opts                                      => $hive_server_opts,
        hive_metastore_opts                                   => $hive_metastore_opts,
        metastore_host                                        => $metastore_host,
        java_home                                             => $java_home,
        # Precaution for CVE-2018-1284
        hive_server_udf_blacklist                             => 'xpath,xpath_string,xpath_boolean,xpath_number,xpath_double,xpath_float,xpath_long,xpath_int,xpath_short',

        # Optional security configs
        hive_metastore_sasl_enabled                           => $hive_metastore_sasl_enabled,
        hive_metastore_kerberos_keytab_file                   => $hive_metastore_kerberos_keytab_file,
        hive_metastore_kerberos_principal                     => $hive_metastore_kerberos_principal,
        hive_server2_authentication                           => $hive_server2_authentication,
        hive_server2_authentication_kerberos_principal        => $hive_server2_authentication_kerberos_principal,
        hive_server2_authentication_kerberos_keytab           => $hive_server2_authentication_kerberos_keytab,
        jdbc_host                                             => $hive_metastore_jdbc_host,
        jdbc_port                                             => $hive_metastore_jdbc_port,
        jdbc_username                                         => $hive_metastore_jdbc_user,
        jdbc_password                                         => $hive_metastore_jdbc_password,
        jdbc_database                                         => $hive_metastore_database,
        jdbc_driver                                           => 'com.mysql.jdbc.Driver',
        deploy_jdbc_settings                                  => $deploy_jdbc_settings,
        config_files_group_ownership                          => $config_files_group_ownership,
        hive_cluster_delegation_token_store_class             => $hive_cluster_delegation_token_store_class,
        hive_metastore_disallow_incompatible_col_type_changes => $hive_metastore_disallow_incompatible_col_type_changes,

        # Optional logging configuration
        hive_log4j_version                                    => $hive_log4j_version,
    }

    # Set up a wrapper script for beeline, the command line
    # interface to HiveServer2 and install it at
    # /usr/local/bin/beeline

    file { '/etc/beeline.ini':
        content => epp('profile/hive/client/beeline.ini.epp',
        {
            hiveserver_host    => $hiveserver_host,
            hiveserver_port    => $hiveserver_port,
            kerberos_principal => $hive_server2_authentication_kerberos_principal
        }),
        mode    => '0555',
    }

    file { '/usr/local/bin/beeline':
        source => 'puppet:///modules/profile/hive/client/beeline_wrapper.py',
        mode   => '0755',
    }
}
