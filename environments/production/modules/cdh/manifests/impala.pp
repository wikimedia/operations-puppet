# == Class impala
# Installs impala-shell client
# And includes cdh:impala::config to put
# hdfs-site.xml, core-site.xml and hdfs-site.xml in
# /etc/impala/conf.
#
# All other impala classes inherit from this one.
#
# Please make sure you set
#    dfs_datanode_hdfs_blocks_metadata_enabled => true,
# when you include cdh::hadoop.  If you don't, impala won't work!
#
# == Parameters
# $master_host - hostname where impala master daemons are running.  Default: 127.0.0.1
#
class cdh::impala(
    $master_host = '127.0.0.1',
) {
    Class['hive']   -> Class['impala']

    package { ['impala', 'impala-shell']:
        ensure => 'installed',
    }

    class { 'cdh::impala::config':
        require => Package['impala'],
    }

    $config_directory = $cdh::impala::config::config_directory

    # These are here instead of in cdh::impala::config because they
    # are symlinks, and don't need to override anything.
    file { "${config_directory}/core-site.xml":
        ensure => 'link',
        target => "${cdh::hadoop::config_directory}/core-site.xml",
    }

    file { "${config_directory}/hive-site.xml":
        ensure => 'link',
        target => "${cdh::hive::config_directory}/hive-site.xml",
    }
}
