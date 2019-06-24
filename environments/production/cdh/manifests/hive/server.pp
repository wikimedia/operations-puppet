# == Class cdh::hive::server
# Configures hive-server2.  Requires that cdh::hadoop is included so that
# hadoop-client is available to create hive HDFS directories.
#
# See: http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH5/latest/CDH5-Installation-Guide/cdh5ig_hiveserver2_configure.html
#
# == Parameters
# $port          - Port on which hive-server2 listens.  Default: undef
# $use_kerberos  - Use kerberos auth to create HDFS directories.
#
class cdh::hive::server(
    $port             = undef,
    $use_kerberos     = false,
)
{
    # cdh::hive::server requires hadoop client and configs are installed.
    Class['cdh::hadoop'] -> Class['cdh::hive::server']
    Class['cdh::hive']   -> Class['cdh::hive::server']

    package { 'hive-server2':
        ensure => 'installed',
        alias  => 'hive-server',
    }

    # sudo -u hdfs hdfs dfs -mkdir /user/hive
    # sudo -u hdfs hdfs dfs -chmod 0775 /user/hive
    # sudo -u hdfs hdfs dfs -chown hive:hadoop /user/hive
    cdh::hadoop::directory { '/user/hive':
        owner        => 'hive',
        group        => 'hadoop',
        mode         => '0775',
        use_kerberos => $use_kerberos,
        require      => Package['hive'],
    }
    # sudo -u hdfs hdfs dfs -mkdir /user/hive/warehouse
    # sudo -u hdfs hdfs dfs -chmod 1777 /user/hive/warehouse
    # sudo -u hdfs hdfs dfs -chown hive:hadoop /user/hive/warehouse
    cdh::hadoop::directory { '/user/hive/warehouse':
        owner        => 'hive',
        group        => 'hadoop',
        mode         => '1777',
        use_kerberos => $use_kerberos,
        require      => Cdh::Hadoop::Directory['/user/hive'],
    }

    service { 'hive-server2':
        ensure     => 'running',
        require    => [
            Package['hive-server2'],
            Cdh::Hadoop::Directory['/user/hive/warehouse'],
        ],
        hasrestart => true,
        hasstatus  => true,
    }
}