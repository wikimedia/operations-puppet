# SPDX-License-Identifier: Apache-2.0
# == Class bigtop::hive::server
# Configures hive-server2.  Requires that bigtop::hadoop is included so that
# hadoop-client is available to create hive HDFS directories.
#
# See: http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH5/latest/CDH5-Installation-Guide/cdh5ig_hiveserver2_configure.html
#
# == Parameters
# $port          - Port on which hive-server2 listens.  Default: undef
#
class bigtop::hive::server( $port = undef ) {

    # bigtop::hive::server requires hadoop client and configs are installed.
    Class['bigtop::hadoop'] -> Class['bigtop::hive::server']
    Class['bigtop::hive']   -> Class['bigtop::hive::server']

    package { 'hive-server2':
        ensure => 'installed',
        alias  => 'hive-server',
    }

    # sudo -u hdfs hdfs dfs -mkdir /user/hive
    # sudo -u hdfs hdfs dfs -chmod 0775 /user/hive
    # sudo -u hdfs hdfs dfs -chown hive:hadoop /user/hive
    bigtop::hadoop::directory { '/user/hive':
        owner   => 'hive',
        group   => 'hadoop',
        mode    => '0775',
        require => Package['hive'],
    }
    # sudo -u hdfs hdfs dfs -mkdir /user/hive/warehouse
    # sudo -u hdfs hdfs dfs -chmod 1777 /user/hive/warehouse
    # sudo -u hdfs hdfs dfs -chown hive:hadoop /user/hive/warehouse
    bigtop::hadoop::directory { '/user/hive/warehouse':
        owner   => 'hive',
        group   => 'hadoop',
        mode    => '1777',
        require => Bigtop::Hadoop::Directory['/user/hive'],
    }

    service { 'hive-server2':
        ensure     => 'running',
        require    => [
            Package['hive-server2'],
            Bigtop::Hadoop::Directory['/user/hive/warehouse'],
        ],
        hasrestart => true,
        hasstatus  => true,
    }
}