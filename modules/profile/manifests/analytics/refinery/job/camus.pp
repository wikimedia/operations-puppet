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
# [*http_proxy_host*]
#    If set, Java will be configured to use an HTTP proxy.
#    Useful if you are using remove eventstreamconfig.
#    Default: undef
#
# [*http_proxy_port*]
#   Default: 8080
#
# Description of Camus jobs declared here:
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
class profile::analytics::refinery::job::camus(
    String $kafka_cluster_name         = lookup('profile::analytics::refinery::job::camus::kafka_cluster_name', { 'default_value' => 'jumbo-eqiad' }),
    Boolean $monitoring_enabled        = lookup('profile::analytics::refinery::job::camus::monitoring_enabled', { 'default_value' => false }),
    Optional[String] $http_proxy_host  = lookup('http_proxy_host', { 'default_value' => undef }),
    Optional[Integer] $http_proxy_port = lookup('http_proxy_port', { 'default_value' => 8080 }),
    Wmflib::Ensure $ensure_timers      = lookup('profile::analytics::refinery::job::camus::ensure_timers', { 'default_value' => 'present' }),
) {
    require ::profile::hadoop::common
    require ::profile::analytics::refinery

    $kafka_config  = kafka_config($kafka_cluster_name)
    $kafka_brokers = $kafka_config['brokers']['string']

    $hadoop_cluster_name = $::profile::hadoop::common::cluster_name

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
        camus_jar           => "${profile::analytics::refinery::path}/artifacts/org/wikimedia/analytics/camus-wmf/camus-wmf-0.1.0-wmf12.jar",
        check_jar           => "${profile::analytics::refinery::path}/artifacts/org/wikimedia/analytics/refinery/refinery-camus-0.0.137.jar",
        check               => $monitoring_enabled,
        # Email reports if CamusPartitionChecker finds errors.
        check_email_target  => $check_email_target,
        environment         => $systemd_env,
        http_proxy_host     => $http_proxy_host,
        http_proxy_port     => $http_proxy_port,
        monitoring_enabled  => $monitoring_enabled,
    }

    # Import legacy eventlogging_* topics into /wmf/data/raw/eventlogging
    # once every hour.
    camus::job { 'eventlogging':
        camus_properties => {
            'kafka.whitelist.topics'        => '^eventlogging_.+',
            # During migration to EventGate, events will have both meta.dt and dt.
            # meta.dt is set by EventGate and is more trustable than dt, which after
            # migration to EventGate is set by the client.
            'camus.message.timestamp.field' => 'meta.dt,dt',
            # Set this to at least the number of topic/partitions you will be importing.
            'mapred.map.tasks'              => '100',
        },
        # Don't need to write _IMPORTED flags for EventLogging data
        check_dry_run    => true,
        # Only check these topic, since they should have data every hour.
        check_java_opts  => '-Dkafka.whitelist.topics="^eventlogging_(NavigationTiming|VirtualPageView)"',
        interval         => '*-*-* *:05:00',
    }

    # Import atskafka_test_webrequest_text topic into
    # /wmf/data/raw/atskafka_test_webrequest_text every 10 minutes, check runs
    # and flag fully imported hours.
    # TODO(klausman): Remove this once we are confident that ATSKafka and
    # VarnishKafka report the same event streams (cf. T254317)
    camus::job { 'atskafka_test_webrequest_text':
        camus_properties => {
            'kafka.whitelist.topics'          => 'atskafka_test_webrequest_text',
            'mapreduce.job.queuename'         => 'essential',
            'camus.message.timestamp.field'   => 'dt',
            # Set this to at least the number of topic/partitions you will be importing.
            'mapred.map.tasks'                => '12',
            # This camus runs every 30 minutes, so limiting it to 29 should keep runs fresh.
            'kafka.max.pull.minutes.per.task' => '29',
        },
        # Don't want to check this job, it is temporary and for testing.
        check            => false,
        interval         => '*-*-* *:00/30:00',
    }

    # Used to determine the topic prefixes of topics used for the CamusPartitionChecker
    # kafka.whitelist.topics on the eventgate-main event serivce job.
    # If a Datacenter is deactivated due to e.g. a datacenter switchover, you should comment
    # out the deactive datacenter to avoid false alerts.
    # In the future, if we can enable canary events for eventgate-main streams, we
    # shouldn't need this anymore.
    $active_datacenters = [
        # 'eqiad',
        'codfw',
    ]
    $check_topic_whitelist_prefixes = "(${active_datacenters.join('|')})"

    # Shortcut for declaring a camus job that imports streams from specific event services.
    # We want separate camus jobs for each event service as their throughput volume can
    # vary significantly, and we don't want high volume topics to starve out small ones.
    # See also:
    # https://wikitech.wikimedia.org/wiki/Event_Platform/EventGate#EventGate_clusters
    $event_service_jobs = {
        'eventgate-analytics-external' => {
            'camus_properties' =>  {
                # eventgate-analytics-external handles both legacy eventlogging_.* streams.
                # as well as new event platform based streams. The eventlogging_.* topics
                # are different enough, so we use a separate camus job (declared above)
                # to import those.  Perhaps one day we can merge these jobs, but not today! :)
                'kafka.blacklist.topics'        => '^eventlogging_.*',
                # Set this to at least the number of topic-partitions you will be importing.
                'mapred.map.tasks'              => '10',
            },
            'interval' => '*-*-* *:25:00',
        },

        'eventgate-analytics' => {
            'camus_properties' =>  {
                # Set this to at least the number of topic-partitions you will be importing.
                'mapred.map.tasks'              => '60',
            },
            'interval' => '*-*-* *:15:00',
        },

        'eventgate-main' => {
            'camus_properties' =>  {
                # eventgate-main handles event platform streams, as well as 'schemaless' mediawiki job
                # streams.  We use a separate camus job (for now) to import mediawiki job
                # events into a separate /wmf/data/raw/mediawiki_job etl.destination.path.
                # We need to exclude the mediawiki job topics from this job.
                'kafka.blacklist.topics'        => '^(eqiad|codfw)\\.mediawiki\\.job\\..*',
                # Set this to at least the number of topic-partitions you will be importing.
                'mapred.map.tasks'              => '40',
            },
            # Check the test topics and resource_change topics.
            # resource_change and revision-create should always have data every hour.
            # In the future, if we can enable canary events for more streams in eventgate-main,
            # we can rely on those instead of this whitlelist for discovering the topics to check.
            # NOTE: since this ends up in the systemd unit ExecStart command, we need
            # extra backslash escapes.
            'check_java_opts' => "-Dkafka.whitelist.topics=\"^(eqiad|codfw)\\\\.eventgate-main\\\\.test\\\\.event|${check_topic_whitelist_prefixes}\\\\.mediawiki\\\\.(resource_change|revision-create)\"",
            'interval' => '*-*-* *:05:00',
        },
    }

    # Declare each of the $event_service_jobs.
    $event_service_jobs.each |String $event_service_name, Hash $parameters| {

        # Default camus properties shared by all event importing jobs.
        # Specific parameters are provided in $event_service_jobs.
        $camus_properties_events = {
            'etl.destination.path'          => "hdfs://${hadoop_cluster_name}/wmf/data/raw/event",
            'camus.message.timestamp.field' => 'meta.dt',
            # Build kafka.whitelist.topics using EventStreamConfig API.
            'eventstreamconfig.uri'              => 'https://meta.wikimedia.org/w/api.php',
            # Only get topics for streams that have this destination_event_service set to event_service_name
            'eventstreamconfig.settings_filters' => "destination_event_service:${event_service_name}",
        }

        # Override settings_filters to only check topics that have canary_events_enabled,
        # unless check_java_opts is explicitly set in $the event_service_job hash declared above.
        $check_java_opts = $parameters['check_java_opts'] ? {
            undef   => "-Deventstreamconfig.settings_filters=${camus_properties_events['eventstreamconfig.settings_filters']},canary_events_enabled:true",
            default => $parameters['check_java_opts'],
        }

        camus::job { "${event_service_name}_events":
            # Being replaced by gobblin.  T271232
            ensure           => 'absent',
            camus_properties => merge(
                $camus_properties_events,
                $parameters['camus_properties'],
            ),
            # Don't need to write _IMPORTED flags for event data
            check_dry_run    => true,
            check_java_opts  => $check_java_opts,
            interval         => $parameters['interval'],
        }
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
}
