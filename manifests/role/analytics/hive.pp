# role/analytics/hive.pp
#
# Role classes for Analytics Hive client and server nodes.
# These role classes will configure Hive properly in either
# the Analytics labs or Analytics production environments.
#
# If you are using these in labs, you must include hive::server
# on your primary Hadoop NameNode.
#
# These classes require role::analytics::hadoop::client
# has already been applied.  They infer some of their
# configurations from that role.
#


# == Class role::analytics::hive
# Installs base configs for hive client nodes
#
class role::analytics::hive::client {
    # require zookeeper config to get zookeeper hosts array.
    require role::analytics::zookeeper::config
    Class['role::analytics::hadoop::client'] -> Class['role::analytics::hive::client']

    # include common labs or production hadoop configs
    # based on $::realm
    if ($::realm == 'labs') {
        include role::analytics::hive::labs
        $cdh_module_name = 'cdh'
    }
    else {
        include role::analytics::hive::production
        $cdh_module_name = 'cdh4'
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

    # make sure mysql-server is installed before
    # we apply our MySQL Hive Metastore database class.
    Package['mysql-server'] -> Class["${cdh_module_name}::hive::metastore::mysql"]

    # Setup Hive server and Metastore
    class { "${cdh_module_name}::hive::master": }
}



### The following classes should not be included directly.
### You should either include role::analytics::hive::client
### or role::analytics::hive::server.

# == Class role::analytics::hive::production
# Installs and configures hive for WMF production environment.
#
class role::analytics::hive::production {
    include passwords::analytics

    class { '::cdh4::hive':
        metastore_host  => 'analytics1027.eqiad.wmnet',
        jdbc_password   => $passwords::analytics::hive_jdbc_password,
        zookeeper_hosts => $role::analytics::zookeeper::config::hosts_array,
        auxpath         => 'file:///usr/lib/hcatalog/share/hcatalog/hcatalog-core-0.5.0-cdh4.3.1.jar',
    }

    # Include hcatalog class so that Hive client's can use
    # ths JsonSerDe from it.  (This class is no longer needed in CDH5,
    # and will be removed when we upgrade).
    class { '::cdh4::hcatalog': }
}

# == Class role::analytics::hive::labs
# Installs and configures hive for WMF Labs environment.
#
class role::analytics::hive::labs {
    class { '::cdh::hive':
        metastore_host  => $role::analytics::hadoop::labs::namenode_hosts[0],
        zookeeper_hosts => $role::analytics::zookeeper::config::hosts_array,
        auxpath         => 'file:///usr/lib/hive-hcatalog/share/hcatalog/hive-hcatalog-core-0.12.0-cdh5.0.2.jar',
    }
}
