# == Class cdh::hadoop::nodemanager
# Installs and configures a Hadoop NodeManager worker node.
#
class cdh::hadoop::nodemanager {
    Class['cdh::hadoop'] -> Class['cdh::hadoop::nodemanager']


    package { ['hadoop-yarn-nodemanager', 'hadoop-mapreduce']:
        ensure => 'installed',
    }

    $nofiles_ulimit = $cdh::hadoop::yarn_nodemanager_nofiles_ulimit
    # Some NodeManager defaults can be overridden
    file { '/etc/default/hadoop-yarn-nodemanager':
        content => template('cdh/hadoop/hadoop-yarn-nodemanager.default.erb'),
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
    service { 'hadoop-yarn-nodemanager':
        ensure     => 'running',
        enable     => true,
        hasstatus  => true,
        hasrestart => true,
        alias      => 'nodemanager',
        require    => [
            Package['hadoop-yarn-nodemanager', 'hadoop-mapreduce'],
            File['/etc/default/hadoop-yarn-nodemanager'],
        ],
    }
}

