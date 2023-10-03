# SPDX-License-Identifier: Apache-2.0
# == Class bigtop::hadoop::nodemanager
# Installs and configures a Hadoop NodeManager worker node.
#
# == Params
#
# [*yarn_use_multi_spark_shufflers*]
#   Boolean: This parameter determines whether or not the host should
#   install the packages containing the spark shuffler.
#
# [*yarn_multi_spark_shuffler_versions*]
#   This is a list of major.minor versions of spark shuffler to install.
#   This has no effect if yarn_use_multi_spark_shufflers is false.

class bigtop::hadoop::nodemanager (
    Boolean $yarn_use_multi_spark_shufflers                           = false,
    Array[Bigtop::Spark::Version] $yarn_multi_spark_shuffler_versions = [],
) {
    Class['bigtop::hadoop'] -> Class['bigtop::hadoop::nodemanager']

    package { ['hadoop-yarn-nodemanager', 'hadoop-mapreduce']:
        ensure  => 'installed',
        require => User['yarn'],
    }

    if $yarn_use_multi_spark_shufflers and $yarn_multi_spark_shuffler_versions.length > 0 {
        $yarn_multi_spark_shuffler_versions.each | $version | {
            ensure_packages ("yarn-spark-${version}-shuffler")
        }
    }

    $nofiles_ulimit = $bigtop::hadoop::yarn_nodemanager_nofiles_ulimit
    # Some NodeManager defaults can be overridden
    file { '/etc/default/hadoop-yarn-nodemanager':
        content => template('bigtop/hadoop/hadoop-yarn-nodemanager.default.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
    }

    # Some Hadoop jobs need Zookeeper libraries, but for some reason they
    # are not installed via package dependencies.  Install the CDH
    # zookeeper package here explicitly.  This avoids
    # java.lang.NoClassDefFoundError: org/apache/zookeeper/KeeperException
    # errors.
    if !defined(Package['zookeeper']) {
        package { 'zookeeper':
            ensure => 'installed'
        }
    }

    # NodeManager (YARN TaskTracker)
    # The override was added for https://phabricator.wikimedia.org/T281792
    # The TaskMax value has been calculated as 80% of the lowest kernel.pid_max
    # among the Hadoop workers. The value 'infinity' may also be used for more
    # flexibility, but due to other important daemons requiring threads on the host
    # (HDFS Datanode and Journalnode) we want to be careful.
    systemd::service { 'hadoop-yarn-nodemanager':
        ensure         => 'present',
        restart        => true,
        override       => true,
        content        => "[Service]\nTasksMax=26214\n",
        service_params => {
            ensure     => 'running',
            alias      => 'nodemanager',
            hasstatus  => true,
            enable     => true,
            hasrestart => true,
        },
        require        => [
            Package['hadoop-yarn-nodemanager', 'hadoop-mapreduce'],
            File['/etc/default/hadoop-yarn-nodemanager'],
        ],
    }
}

