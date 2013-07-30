# role/analytics/hive.pp
#
# Role classes for Analytics Hive client and server nodes.
# These role classes will configure Hive properly in either
# the Analytics labs or Analytics production environments.
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
    }
    else {
        include role::analytics::hive::production
    }
}



# == Class role::analytics::hive::server
# Sets up hive server and hive metastore.
#
class role::analytics::hive::server inherits role::analytics::hive::client {
    if (!defined(Package['mysql-server'])) {
        package { 'mysql-server':
            ensure => 'installed',
        }
    }

    # make sure mysql-server is installed before
    # we apply our MySQL Hive Metastore database class.
    Package['mysql-server'] -> Class['::cdh4::hive::metastore::mysql']

    # Setup Hive server and Metastore
    class { '::cdh4::hive::master': }
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
        zookeeper_hosts => $role::analytics::zookeeper::hosts_array,
    }
}

# == Class role::analytics::hive::labs
# Installs and configures hive for WMF Labs environment.
#
class role::analytics::hive::labs {
    class { '::cdh4::hive':
        metastore_host  => $role::analytics::hadoop::labs::namenode_hosts[0],
        zookeeper_hosts => $role::analytics::zookeeper::hosts_array,
    }
}