# == Class cdh::hadoop::historyserver
# Installs and starts up a Hadoop YARN HistoryServer.
# This will ensure that the HDFS /user/history exists.
# This class may only be included on the NameNode Master
# Hadoop node.
#
class cdh::hadoop::historyserver {
    Class['cdh::hadoop::namenode'] -> Class['cdh::hadoop::historyserver']

    # Create HistoryServer HDFS directories.
    # See: http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH5/latest/CDH5-Installation-Guide/cdh5ig_yarn_cluster_deploy.html?scroll=topic_11_4_9_unique_1
    cdh::hadoop::directory { '/user/history':
        # sudo -u hdfs hdfs dfs -mkdir /user/history
        # sudo -u hdfs hdfs dfs -chmod -R 1777 /user/history
        # sudo -u hdfs hdfs dfs -chown yarn /user/history
        owner   => 'yarn',
        group   => 'hdfs',
        mode    => '1777',
        # Make sure HDFS directories are created before
        # historyserver is installed and started, but after
        # the namenode.
        require => [Service['hadoop-hdfs-namenode'], Cdh::Hadoop::Directory['/user']],
    }

    package { 'hadoop-mapreduce-historyserver':
        ensure  => 'installed',
        require => Cdh::Hadoop::Directory['/user/history'],
    }

    service { 'hadoop-mapreduce-historyserver':
        ensure     => 'running',
        enable     => true,
        hasstatus  => true,
        hasrestart => true,
        alias      => 'historyserver',
        require    => Package['hadoop-mapreduce-historyserver'],
    }
}
