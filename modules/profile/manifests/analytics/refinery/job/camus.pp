# == Class profile::analytics::refinery::job::camus
# Uses camus::job to set up cron jobs to
# import data from Kafka into Hadoop.
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
# [*use_kerberos*]
#   Run kinit before executing any command.
#   Default: false
#
class profile::analytics::refinery::job::camus(
    $kafka_cluster_name = lookup('profile::analytics::refinery::job::camus::kafka_cluster_name', { 'default_value' => 'jumbo' }),
    $monitoring_enabled = lookup('profile::analytics::refinery::job::camus::monitoring_enabled', { 'default_value' => false }),
    $use_kerberos       = lookup('profile::analytics::refinery::job::camus::use_kerberos', { 'default_value' => false }),
) {
    require ::profile::hadoop::common
    require ::profile::analytics::refinery

    $kafka_config  = kafka_config($kafka_cluster_name)
    $kafka_brokers = suffix($kafka_config['brokers']['array'], ':9092')

    $kafka_brokers_jumbo     = suffix($kafka_config['brokers']['array'], ':9092')

    $env = "export PYTHONPATH=\${PYTHONPATH}:${profile::analytics::refinery::path}/python"
    $systemd_env = {
        'PYTHONPATH' => "\${PYTHONPATH}:${profile::analytics::refinery::path}/python",
    }

    # Make all uses of camus::job set default kafka_brokers and camus_jar.
    # If you build a new camus or refinery, and you want to use it, you'll
    # need to change these.  You can also override these defaults
    # for a particular camus::job instance by setting the parameter on
    # the camus::job declaration.
    Camus::Job {
        script              => "${profile::analytics::refinery::path}/bin/camus",
        kafka_brokers       => $kafka_brokers,
        camus_jar           => "${profile::analytics::refinery::path}/artifacts/org/wikimedia/analytics/camus-wmf/camus-wmf-0.1.0-wmf9.jar",
        check_jar           => "${profile::analytics::refinery::path}/artifacts/org/wikimedia/analytics/refinery/refinery-camus-0.0.90.jar",
        # Email reports if CamusPartitionChecker finds errors.
        check_email_enabled => $monitoring_enabled,
        environment         => $systemd_env,
        template_variables  => {
            'hadoop_cluster_name' => $::profile::hadoop::common::cluster_name
        },
        use_kerberos        => $use_kerberos,
    }


    # Import webrequest_* topics into /wmf/data/raw/webrequest
    # every 10 minutes, check runs and flag fully imported hours.
    camus::job { 'webrequest':
        check                 => $monitoring_enabled,
        kafka_brokers         => $kafka_brokers_jumbo,
        check_topic_whitelist => 'webrequest_(upload|text)',
        interval              => '*-*-* *:00/10:00',
    }

    # Import eventlogging_* topics into /wmf/data/raw/eventlogging
    # once every hour.
    camus::job { 'eventlogging':
        kafka_brokers         => $kafka_brokers_jumbo,
        check                 => true,
        # Don't need to write _IMPORTED flags for EventLogging data
        check_dry_run         => true,
        # Only check these topic, since they should have data every hour.
        check_topic_whitelist => 'eventlogging_(NavigationTiming|VirtualPageView)',
        interval              => '*-*-* *:05:00',
    }

    # Import eventbus topics into /wmf/data/raw/eventbus
    # once every hour.
    # Also check that camus is always finding data in the revision-create
    # topic from the primary mediawiki datacenter.
    # NOTE: Using mediawiki::state is a bit of a hack; this data should
    # be read from confd/etcd directly instead of using this hacky function.
    $primary_mediawiki_dc = $::realm ? {
        'labs'  => 'eqiad',
        default => mediawiki::state('primary_dc'),
    }

    camus::job { 'eventbus':
        kafka_brokers         => $kafka_brokers_jumbo,
        check                 => $monitoring_enabled,
        # Don't need to write _IMPORTED flags for EventBus data
        check_dry_run         => true,
        # Only check this topic, since it should always have data for every hour
        check_topic_whitelist => "${primary_mediawiki_dc}.mediawiki.revision-create",
        interval              => '*-*-* *:05:00',
    }

    # Import eventbus mediawiki.job queue topics into /wmf/data/raw/mediawiki_job
    # once every hour.
    camus::job { 'mediawiki_job':
        kafka_brokers => $kafka_brokers_jumbo,
        interval      => '*-*-* *:10:00',
    }

    # Import eventlogging-client-side events for backup purposes
    camus::job { 'eventlogging-client-side':
        kafka_brokers => $kafka_brokers_jumbo,
        interval      => '*-*-* *:20:00',
    }

    # Import netflow queue topics into /wmf/data/raw/netflow
    # once every hour.
    camus::job { 'netflow':
        kafka_brokers => $kafka_brokers_jumbo,
        interval      => '*-*-* *:30:00',
    }
}
