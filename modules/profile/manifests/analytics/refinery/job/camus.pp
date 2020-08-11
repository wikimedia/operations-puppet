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
# Description of Camus jobs declared here:
#
# - webrequest
#   Ingests webrequest_text and webrequest_upload topics into
#   /wmf/data/raw/webrequest/.
#
# - eventlogging
#   Ingests legacy eventlogging_.+ topics into /wmf/data/raw/eventlogging/.
#
# - eventgate-*
#   Each eventgate-* camus job is responsible for importing the topics for streams
#   configured in Mediawiki EventStreamConfig that have destination_event_service name
#   matching the eventgate service name.
#   Note: we don't yet import eventgate-logging-external streams, as these are not
#   (yet) mirrored to Kafka jumbo.
#
# - mediawiki_events
#   Ingests whitelisted mediawiki.*  (non job) events into /wmf/data/raw/event/.
#   TO BE DEPRECATED in favor of eventgate-main job.
#
# - mediawiki_job
#   Ingests mediawiki.job.* topics into /wmf/data/raw/mediawiki_job.
#
# - eventlogging-client-side
#   Ingests the eventlogging-client-side topic into /wmf/data/raw/eventlogging_client_side
#   for backup purposes.
#
# - netflow
#   Ingests the netflow topic into /wmf/data/raw/netflow.
#
class profile::analytics::refinery::job::camus(
    $kafka_cluster_name = lookup('profile::analytics::refinery::job::camus::kafka_cluster_name', { 'default_value' => 'jumbo-eqiad' }),
    $monitoring_enabled = lookup('profile::analytics::refinery::job::camus::monitoring_enabled', { 'default_value' => false }),
    $use_kerberos       = lookup('profile::analytics::refinery::job::camus::use_kerberos', { 'default_value' => false }),
    $ensure_timers      = lookup('profile::analytics::refinery::job::camus::ensure_timers', { 'default_value' => 'present' }),
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
        true  => 'analytics-alerts@wikimedia.org',
        false => undef,
    }

    # Make all uses of camus::job set default kafka_brokers and camus_jar.
    # If you build a new camus or refinery, and you want to use it, you'll
    # need to change these.  You can also override these defaults
    # for a particular camus::job instance by setting the parameter on
    # the camus::job declaration.
    Camus::Job {
        ensure              => $ensure_timers,
        script              => "${profile::analytics::refinery::path}/bin/camus",
        kafka_brokers       => $kafka_brokers,
        hadoop_cluster_name => $hadoop_cluster_name,
        # TODO upgrade this default to wmf10 once wmf10 is proved to work for eventlogging job.
        camus_jar           => "${profile::analytics::refinery::path}/artifacts/org/wikimedia/analytics/camus-wmf/camus-wmf-0.1.0-wmf9.jar",
        check_jar           => "${profile::analytics::refinery::path}/artifacts/org/wikimedia/analytics/refinery/refinery-camus-0.0.128.jar",
        check               => $monitoring_enabled,
        # Email reports if CamusPartitionChecker finds errors.
        check_email_target  => $check_email_target,
        environment         => $systemd_env,
        use_kerberos        => $use_kerberos,
        monitoring_enabled  => $monitoring_enabled,
    }


    # Import webrequest_* topics into /wmf/data/raw/webrequest
    # every 10 minutes, check runs and flag fully imported hours.
    camus::job { 'webrequest':
        camus_properties      => {
            'kafka.whitelist.topics'          => 'webrequest_text,webrequest_upload',
            'mapreduce.job.queuename'         => 'essential',
            'camus.message.timestamp.field'   => 'dt',
            # Set this to at least the number of topic/partitions you will be importing.
            # 2 webrequest topics with 24 partitions each. 2 * 24 = 48.
            'mapred.map.tasks'                => '48',
            # This camus runs every 10 minutes, so limiting it to 9 should keep runs fresh.
            'kafka.max.pull.minutes.per.task' => '9',
            # Set HDFS umask so that webrequest files and directories created by Camus are not world readable.
            'fs.permissions.umask-mode'       => '027'
        },
        check_topic_whitelist => 'webrequest_(upload|text)',
        interval              => '*-*-* *:00/10:00',
    }

    # Import legacy eventlogging_* topics into /wmf/data/raw/eventlogging
    # once every hour.
    camus::job { 'eventlogging':
        camus_properties      => {
            'kafka.whitelist.topics'        => '^eventlogging_.+',
            # During migration to EventGate, events will have both meta.dt and dt.
            # meta.dt is set by EventGate and is more trustable than dt, which after
            # migration to EventGate is set by the client.
            'camus.message.timestamp.field' => 'meta.dt,dt',
            # Set this to at least the number of topic/partitions you will be importing.
            'mapred.map.tasks'              => '100',
        },
        # TODO: Remove this once default has been changed to wmf10.
        camus_jar             => "${profile::analytics::refinery::path}/artifacts/org/wikimedia/analytics/camus-wmf/camus-wmf-0.1.0-wmf10.jar",
        # Don't need to write _IMPORTED flags for EventLogging data
        check_dry_run         => true,
        # Only check these topic, since they should have data every hour.
        check_topic_whitelist => '^eventlogging_(NavigationTiming|VirtualPageView)',
        interval              => '*-*-* *:05:00',
    }

    # Shortcut for declaring a camus job that imports streams from specific event services.
    # We want separate camus jobs for each event service as their throughput volume can
    # vary significantly, and we don't want high volume topics to starve out small ones.
    $event_service_jobs = {
        'eventgate-analytics-external' => {
            'camus_properties' =>  {
                'etl.destination.path'          => "hdfs://${hadoop_cluster_name}/wmf/data/raw/event",
                'camus.message.timestamp.field' => 'meta.dt',
                # eventgate-analytics-external handles both legacy eventlogging_.* streams.
                # as well as new event platform based streams. The eventlogging_.* topics
                # are different enough, so we use a separate camus job (declared above)
                # to import those.
                'kafka.blacklist.topics'        => '^eventlogging_.*',
                # Set this to at least the number of topic-partitions you will be importing.
                'mapred.map.tasks'              => '10',
            },
            'interval' => '*-*-* *:30:00',
        },

        'eventgate-analytics' => {
            'camus_properties' =>  {
                'etl.destination.path'          => "hdfs://${hadoop_cluster_name}/wmf/data/raw/event",
                'camus.message.timestamp.field' => 'meta.dt',
                # Set this to at least the number of topic-partitions you will be importing.
                'mapred.map.tasks'              => '60',
            },
            # Check the test topics and mediawiki.api-requests topics.  mediawiki.api-request should
            # always have data every hour in both datacenters.
            'check_topic_whitelist' => '(eqiad|codfw)\\.(eventgate-analytics\\.test\\.event|mediawiki\\.api-request)',
            'interval' => '*-*-* *:05:00',
        },

        # TODO:
        # Add more jobs here as we migrated from static to dynamic topic discovery via EventStreamConfig.
        # - eventgate-main (replaces mediawiki_events job)
    }

    # Declare each of the $event_service_jobs.
    $event_service_jobs.each |String $event_service_name, Hash $parameters| {

        # Default to using .*$event_service_name.test.event for camus checker.
        # We know that there are test topics for this event service should always have
        # events, as they are produced when k8s uses its readinessProbe for the service.
        # We should only check topics we know have data every hour.
        $check_topic_whitelist = $parameters['check_topic_whitelist'] ? {
            undef   => "(eqiad|codfw)\\.${event_service_name}\\.test\\.event",
            default => $parameters['check_topic_whitelist']
        }

        camus::job { "${event_service_name}_events":
            ensure                     => $ensure_timers,
            camus_properties           => $parameters['camus_properties'],
            # Build kafka.whitelist.topics using EventStreamConfig API.
            dynamic_stream_configs     => true,
            # Only get topics for streams that have this destination_event_service set to event_service_name
            stream_configs_constraints => "destination_event_service=${event_service_name}",
            # Don't need to write _IMPORTED flags for event data
            check_dry_run              => true,
            check_topic_whitelist      => $check_topic_whitelist,
            interval                   => $parameters['interval'],
        }
    }

    # Import MediaWiki events into
    # /wmf/data/raw/event once every hour.
    # Also check that camus is always finding data in the revision-create
    # topic from the primary mediawiki datacenter.
    # NOTE: Using mediawiki::state is a bit of a hack; this data should
    # be read from confd/etcd directly instead of using this hacky function.
    $primary_mediawiki_dc = $::realm ? {
        'labs'  => 'eqiad',
        default => mediawiki::state('primary_dc'),
    }
    # Imports MediaWiki (EventBus) events that are produced via eventgate-main
    camus::job { 'mediawiki_events':
        camus_properties      => {
            # Write these into the /wmf/data/raw/event directory
            'etl.destination.path'          => "hdfs://${hadoop_cluster_name}/wmf/data/raw/event",
            'kafka.whitelist.topics'        => '(eqiad|codfw)\.(resource_change|mediawiki\.(page|revision|user|recentchange).*)',
            'camus.message.timestamp.field' => 'meta.dt',
            # Set this to at least the number of topic/partitions you will be importing.
            'mapred.map.tasks'              => '40',
        },
        # This job was called 'eventbus' in the past and still uses the
        # old camus history paths with this name.
        camus_name            => 'eventbus-00',
        # Don't need to write _IMPORTED flags for event data
        check_dry_run         => true,
        # Only check high volume topics that will almost certainly have data every hour.
        check_topic_whitelist => "${primary_mediawiki_dc}.mediawiki.revision-create",
        interval              => '*-*-* *:05:00',
    }

    # Import mediawiki.job queue topics into /wmf/data/raw/mediawiki_job
    # once every hour.
    camus::job { 'mediawiki_job':
        camus_properties => {
            'kafka.whitelist.topics'        => '(eqiad|codfw)\.mediawiki\.job.*',
            'camus.message.timestamp.field' => 'meta.dt',
            # Set this to at least the number of topic/partitions you will be importing.
            'mapred.map.tasks'              => '60',
        },
        check            => false,
        interval         => '*-*-* *:10:00',
    }

    # Import eventlogging-client-side events for backup purposes
    camus::job { 'eventlogging-client-side':
        camus_properties => {
            'etl.destination.path'        => "hdfs://${hadoop_cluster_name}/wmf/data/raw/eventlogging_client_side",
            'kafka.whitelist.topics'      => 'eventlogging-client-side',
            # eventlogging-client-side events are not in JSON format.  They are
            # simple strings separated by tabs. We rely on the fallback mechanism of
            # StringMessageDecoder to use the system time for bucketing.
            'camus.message.decoder.class' => 'com.linkedin.camus.etl.kafka.coders.StringMessageDecoder',
            # Set this to at least the number of topic/partitions you will be importing.
            'mapred.map.tasks'            => '12',
        },
        check            => false,
        interval         => '*-*-* *:20:00',
    }

    # Import netflow queue topics into /wmf/data/raw/netflow
    # once every hour.
    camus::job { 'netflow':
        camus_properties => {
            'kafka.whitelist.topics'         => 'netflow',
            # netflow stamp_inserted timestamps look like 2018-01-30 22:30:00
            'camus.message.timestamp.format' => 'yyyy-MM-dd\' \'HH:mm:ss',
            'camus.message.timestamp.field'  => 'stamp_inserted',
            # Set this to at least the number of topic/partitions you will be importing.
            'mapred.map.tasks'               => '3',
        },
        # No '-00' suffix is used in the netflow camus history dir path.
        # Set camus_name to just 'netflow' to avoid the default -00 prefixing.
        camus_name       => 'netflow',
        check            => false,
        interval         => '*-*-* *:30:00',
    }
}
