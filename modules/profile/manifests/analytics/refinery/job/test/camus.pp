# == Class profile::analytics::refinery::job::test::camus
# Uses camus::job to set up cron jobs to
# import data from Kafka into the Hadoop testing cluster.
#
# == Parameters
# [*kafka_cluster_name*]
#   Name of the Kafka cluster in the kafka_clusters hash that will be used
#   to look up brokers from which Camus will import data.
#   Default: 'jumbo'
#
# [*monitoring_enabled*]
#   Enable monitoring for Camus data imported.
#
class profile::analytics::refinery::job::test::camus(
    String $kafka_cluster_name = lookup('profile::analytics::refinery::job::camus::kafka_cluster_name', { 'default_value' => 'jumbo' }),
    Boolean $monitoring_enabled = lookup('profile::analytics::refinery::job::camus::monitoring_enabled', { 'default_value' => false }),
    Boolean $use_kerberos       = lookup('profile::analytics::refinery::job::camus::use_kerberos', { 'default_value' => false }),
) {
    require ::profile::hadoop::common
    require ::profile::analytics::refinery

    $kafka_config  = kafka_config($kafka_cluster_name)
    $kafka_brokers = $kafka_config['brokers']['string']

    $hadoop_cluster_name = $::profile::hadoop::common::cluster_name

    $env = "export PYTHONPATH=\${PYTHONPATH}:${profile::analytics::refinery::path}/python"
    $systemd_env = {
        'PYTHONPATH' => "\${PYTHONPATH}:${profile::analytics::refinery::path}/python",
    }

    $check_email_target = $monitoring_enabled ? {
        true  => 'ltoscano@wikimedia.org',
        false => undef,
    }

    # Make all uses of camus::job set default kafka_brokers and camus_jar.
    # If you build a new camus or refinery, and you want to use it, you'll
    # need to change these.  You can also override these defaults
    # for a particular camus::job instance by setting the parameter on
    # the camus::job declaration.
    Camus::Job {
        script              => "${profile::analytics::refinery::path}/bin/camus",
        kafka_brokers       => $kafka_brokers,
        hadoop_cluster_name => $hadoop_cluster_name,
        camus_jar           => "${profile::analytics::refinery::path}/artifacts/org/wikimedia/analytics/camus-wmf/camus-wmf-0.1.0-wmf9.jar",
        check_jar           => "${profile::analytics::refinery::path}/artifacts/org/wikimedia/analytics/refinery/refinery-camus-0.0.128.jar",
        check               => $monitoring_enabled,
        # Email reports if CamusPartitionChecker finds errors.
        check_email_target  => $check_email_target,
        environment         => $systemd_env,
        use_kerberos        => $use_kerberos,
    }

    # Import webrequest_* topics into /wmf/data/raw/webrequest
    # every 10 minutes, check runs and flag fully imported hours.
    camus::job { 'webrequest':
        camus_properties      => {
            'kafka.whitelist.topics'          => 'webrequest_test_text',
            'mapreduce.job.queuename'         => 'essential',
            'camus.message.timestamp.field'   => 'dt',
            # Set this to at least the number of topic/partitions you will be importing.
            'mapred.map.tasks'                => '1',
            # This camus runs every 10 minutes, so limiting it to 9 should keep runs fresh.
            'kafka.max.pull.minutes.per.task' => '9',
            # Set HDFS umask so that webrequest files and directories created by Camus are not world readable.
            'fs.permissions.umask-mode'       => '027'
        },
        check_topic_whitelist => 'webrequest_test_text',
        interval              => '*-*-* *:00/10:00',
    }

    # Import eventlogging_NavigationTiming topic into /wmf/data/raw/eventlogging
    # once every hour.
    camus::job { 'eventlogging':
        camus_properties      => {
            'kafka.whitelist.topics'        => 'eventlogging_NavigationTiming',
            'camus.message.timestamp.field' => 'dt',
            'mapred.map.tasks'              => '1',
        },
        # Don't need to write _IMPORTED flags for EventLogging data
        check_dry_run         => true,
        # Only check these topic, since they should have data every hour.
        check_topic_whitelist => 'eventlogging_NavigationTiming',
        interval              => '*-*-* *:05:00',
    }
}
