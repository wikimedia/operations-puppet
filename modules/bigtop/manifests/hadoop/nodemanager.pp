# SPDX-License-Identifier: Apache-2.0
# == Class bigtop::hadoop::nodemanager
# Installs and configures a Hadoop NodeManager worker node.
#
class bigtop::hadoop::nodemanager {
    Class['bigtop::hadoop'] -> Class['bigtop::hadoop::nodemanager']


    package { ['hadoop-yarn-nodemanager', 'hadoop-mapreduce']:
        ensure  => 'installed',
        require => User['yarn'],
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

