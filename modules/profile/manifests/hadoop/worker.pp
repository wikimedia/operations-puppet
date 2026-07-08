# SPDX-License-Identifier: Apache-2.0
# == Class profile::hadoop::worker
#
# Configure a Analytics Hadoop worker node.
#
# == Parameters
#
#  [*monitoring_enabled*]
#    If production monitoring needs to be enabled or not.
#
#  [*use_kerberos*]
#    Make Puppet use Kerberos authentication when executing hdfs commands.
#
class profile::hadoop::worker (
    String $cluster_name                     = lookup('profile::hadoop::common::hadoop_cluster_name'),
    Boolean $monitoring_enabled              = lookup('profile::hadoop::worker::monitoring_enabled', { 'default_value' => false }),
    String $ferm_srange                      = lookup('profile::hadoop::worker::ferm_srange', { 'default_value' => '$DOMAIN_NETWORKS' }),
    Boolean $enable_performance_cpu_governor = lookup('profile::hadoop::worker::enable_performance_cpu_governor', { 'default_value' => false })
) {
    # We are temporarily disabling the processor C-States for Hadoop workers,
    # so the default value for this is false while this investigation is under way.
    # See #T415002 for more details on this trial.
    if $enable_performance_cpu_governor {
        # enable CPU performance governor; see T362922
        class { 'cpufrequtils': }
    }

    require profile::analytics::cluster::packages::common
    require profile::hadoop::common
    require profile::java

    if $monitoring_enabled {
        # Prometheus exporters
        require profile::hadoop::monitoring::datanode
        require profile::hadoop::monitoring::nodemanager
    }

    # Look up in the common hadoop config whether or not this cluster is configured to use multiple spark shufflers
    $yarn_use_multi_spark_shufflers = $profile::hadoop::common::hadoop_config['yarn_use_multi_spark_shufflers'] ? {
        undef   => false,
        default => $profile::hadoop::common::hadoop_config['yarn_use_multi_spark_shufflers'],
    }

    # Look up in the common hadoop config the hash of spark versions in use. We only need the versions here, not their ports.
    $yarn_multi_spark_shuffler_versions = $profile::hadoop::common::hadoop_config['yarn_multi_spark_shuffler_versions'] ? {
        undef   => [],
        default => $profile::hadoop::common::hadoop_config['yarn_multi_spark_shuffler_versions'].keys,
    }

    class { 'bigtop::hadoop::worker':
        disable_yarn_nodemanager           => $facts['networking']['fqdn'] in $profile::hadoop::common::excluded_hosts,
        yarn_use_multi_spark_shufflers     => $yarn_use_multi_spark_shufflers,
        yarn_multi_spark_shuffler_versions => $yarn_multi_spark_shuffler_versions,
    }

    # The HDFS journalnodes are co-located for convenience,
    # but it is not a strict requirement.
    if $facts['networking']['fqdn'] in $::bigtop::hadoop::journalnode_hosts {
        if $monitoring_enabled {
            require profile::hadoop::monitoring::journalnode
        }
        class { 'bigtop::hadoop::journalnode': }
    }

    # Specific rule for HDFS datanode-data to set qos mark
    ferm::service{ 'hadoop-data':
        proto  => 'tcp',
        port   => '50010',
        srange => $ferm_srange,
        prio   => 9,
        qos    => 'low',
    }

    # This allows Hadoop daemons to talk to each other.
    ferm::service{ 'hadoop-access':
        proto  => 'tcp',
        port   => '1024:65535',
        srange => $ferm_srange,
    }

    # Needed to ease enabling Kerberos and Linux containers
    file { '/usr/local/sbin/set_yarn_dir_ownership':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0550',
        source => 'puppet:///modules/profile/hadoop/worker/set_yarn_dir_ownership',
    }

    # Hadoop jobs tend to leave stuff behind. Let's clean everything that's
    # older than 30 days. See https://phabricator.wikimedia.org/T396582
    systemd::tmpfile { 'tmp-hadoop':
        content => 'd /tmp/ - - - 30d',
    }
}
