# == Class cdh::impala::config
# Special config class for impala.  This class only exists to deal with
# puppet annoyances, and should not be directly included.
#
# Impala requires that it have hive-site.xml, core-site.xml
# and hdfs-site.xml in /etc/impala/conf.  Both hive-site.xml and core-site.xml
# should be identical to the ones used by Hive and Hadoop, so we can just
# symlink to those in the cdh::impala class.
# However, Impala has its own hdfs client (written in C++), so it needs
# some special client level settings.  We don't want to duplicate the
# Hadoop properties or the template, so instead, we inherit directly
# from cdh::hadoop, and render a new hdfs-site.xml file with
# all of the inherited properties from hadoop.
# Also, since this class must be evaluated before cdh::impala, and we need
# to know the Impala $config_directory and alternative we are going to use,
# this class is called ::config instead of ::hadoop, and configures
# the $config_directory and alternative.  cdh::impala sets its own
# $config_directory variable that can be refereced from other places
# that need to know it.  Do not try to reference anything in this class!
#
class cdh::impala::config {

    $config_directory = "/etc/impala/conf.${cdh::hadoop::cluster_name}"
    # Create the $cluster_name based $config_directory.
    file { $config_directory:
        ensure  => 'directory',
        require => Package['hive'],
    }
    cdh::alternative { 'impala-conf':
        link => '/etc/impala/conf',
        path => $config_directory,
    }

    # Set these in Impala's version of hdfs-site.xml according to
    # http://www.cloudera.com/content/cloudera/en/documentation/core/latest/topics/impala_config_performance.html#config_performance
    $hdfs_site_impala_extra_properties = {
        'dfs.client.read.shortcircuit'                           => true,
        'dfs.domain.socket.path'                                 => '/var/run/hdfs-sockets/dn',
        'dfs.client.file-block-storage-locations.timeout.millis' => 10000,
    }

    # make sure this directory exists:
    file { ['/var/run/hdfs-sockets', '/var/run/hdfs-sockets/dn']:
        ensure => 'directory',
        owner  => 'root',
        group  => 'hdfs',
        mode   => '0775',
    }

    file { "${config_directory}/hdfs-site.xml":
        content => template('cdh/hadoop/hdfs-site.xml.erb'),
    }
}
