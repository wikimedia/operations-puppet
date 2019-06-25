# == Class cdh::hadoop::namenode
# Installs and configureds Hadoop NameNode.
# This will format the NameNode if it is not
# already formatted.  It will also create
# a common HDFS directory hierarchy.
#
# Note:  If you are using HA NameNode (indicated by setting
# cdh::hadoop::nameservice_id), your JournalNodes should be running before
# this class is applied.
#
class cdh::hadoop::namenode(
    $use_kerberos = false,
    $standby = false,
    $excluded_hosts = [],
) {
    Class['cdh::hadoop'] -> Class['cdh::hadoop::namenode']


    file { "${::cdh::hadoop::config_directory}/hosts.exclude":
        ensure  => present,
        content => template('cdh/hadoop/hosts.exclude.erb'),
    }

    # install namenode daemon package
    package { 'hadoop-hdfs-namenode':
        ensure  => 'installed',
        require => File["${::cdh::hadoop::config_directory}/hosts.exclude"],
    }

    if ($::cdh::hadoop::ha_enabled and $::cdh::hadoop::zookeeper_hosts) {
        if !defined(Package['zookeeper']) {
            package { 'zookeeper':
                ensure => 'installed'
            }
        }

        package { 'hadoop-hdfs-zkfc':
            ensure => 'installed',
        }
    }

    # Ensure that the namenode directory has the correct permissions.
    file { $::cdh::hadoop::dfs_name_dir:
        ensure  => 'directory',
        owner   => 'hdfs',
        group   => 'hdfs',
        mode    => '0700',
        require => Package['hadoop-hdfs-namenode'],
    }

    if $standby {
        $namenode_format_command = '/usr/bin/hdfs namenode -bootstrapStandby -nonInteractive'
    } else {
        $namenode_format_command = '/usr/bin/hdfs namenode -format -nonInteractive'
    }

    # If $dfs_name_dir/current/VERSION doesn't exist, assume
    # NameNode has not been formated.  Format it before
    # the namenode service is started.
    kerberos::exec { 'hadoop-namenode-format':
        command => $namenode_format_command,
        creates => "${::cdh::hadoop::dfs_name_dir_main}/current/VERSION",
        user    => 'hdfs',
        require => [File[$::cdh::hadoop::dfs_name_dir], File["${::cdh::hadoop::config_directory}/hosts.exclude"]],
    }

    service { 'hadoop-hdfs-namenode':
        ensure     => 'running',
        enable     => true,
        hasstatus  => true,
        hasrestart => true,
        alias      => 'namenode',
        require    => Exec['hadoop-namenode-format'],
    }

    if ($::cdh::hadoop::ha_enabled and $::cdh::hadoop::zookeeper_hosts) {
        # Create a znode in ZooKeeper inside of which the automatic failover
        # system stores its data. The command will create a znode in ZooKeeper
        # and it needs to be executed only when the znode is not present.

        # Catch-all if the zookeeper_hosts is not an array.
        $zookeeper_hosts = $::cdh::hadoop::zookeeper_hosts
        $zookeeper_hosts_string = inline_template(
            '<%= Array(@zookeeper_hosts).join(",") %>'
        )

        kerberos::exec { 'hadoop-hdfs-zkfc-init':
            # If the znode created by -formatZK already exists, and for
            # some buggy reason it happens to run, -formatZK will prompt
            # the user to confirm if the znode should be reformatted.
            # Puppet isn't able to answer this question on its own.
            # Default to answering with 'N' if the command asks.
            # This should never happen, but just in case it does,
            # We don't want this eternally unanswered prompt to fill up
            # puppet logs and disks.
            command => 'echo N | hdfs zkfc -formatZK',
            user    => 'hdfs',
            require => [
                Service['hadoop-hdfs-namenode'],
                Package['zookeeper'],
            ],
            # NOTE. zkCli.sh from debian uses different install path than
            # from CDH.  Add both possibilities to PATH.
            path    => '/bin:/usr/bin:/usr/share/zookeeper/bin:/usr/lib/zookeeper/bin',
            # Don't attempt to run this command if the znode already exists
            # or if a Java Exception is returned by the zkCli tool containing
            # the ERROR log (for example when the Zookeeper node is down).
            unless  => "zkCli.sh -server ${zookeeper_hosts_string} \
                stat /hadoop-ha/${::cdh::hadoop::cluster_name} 2>&1 \
                | egrep -q 'ctime|ERROR'",
        }

        # Supporting daemon to enable automatic-failover via health-check.
        # Stores its state in zookeper.
        service { 'hadoop-hdfs-zkfc':
            ensure     => 'running',
            enable     => true,
            hasstatus  => true,
            hasrestart => true,
            require    => [
                Exec['hadoop-hdfs-zkfc-init'],
                Service['hadoop-hdfs-namenode'],
            ],
        }
    }
}
