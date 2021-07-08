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
# [*http_proxy_host*]
#    If set, Java will be configured to use an HTTP proxy.
#    Useful if you are using remove eventstreamconfig.
#    Default: undef
#
# [*http_proxy_port*]
#   Default: 8080
#
class profile::analytics::refinery::job::test::camus(
    String $kafka_cluster_name         = lookup('profile::analytics::refinery::job::camus::kafka_cluster_name', { 'default_value' => 'jumbo' }),
    Boolean $monitoring_enabled        = lookup('profile::analytics::refinery::job::camus::monitoring_enabled', { 'default_value' => false }),
    Optional[String] $http_proxy_host  = lookup('http_proxy_host', { 'default_value' => undef }),
    Optional[Integer] $http_proxy_port = lookup('http_proxy_port', { 'default_value' => 8080 }),
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
        camus_jar           => "${profile::analytics::refinery::path}/artifacts/org/wikimedia/analytics/camus-wmf/camus-wmf-0.1.0-wmf12.jar",
        check_jar           => "${profile::analytics::refinery::path}/artifacts/org/wikimedia/analytics/refinery/refinery-camus-0.0.137.jar",
        check               => $monitoring_enabled,
        # Email reports if CamusPartitionChecker finds errors.
        check_email_target  => $check_email_target,
        environment         => $systemd_env,
        http_proxy_host     => $http_proxy_host,
        http_proxy_port     => $http_proxy_port,
    }

    # Import eventlogging_NavigationTiming topic into /wmf/data/raw/eventlogging
    # once every hour.
    camus::job { 'eventlogging':
        ensure           => 'absent',
        camus_properties => {
            'kafka.whitelist.topics'        => 'eventlogging_NavigationTiming',
            'mapreduce.job.queuename'       => 'essential',
            # During migration to EventGate, events will have both meta.dt and dt.
            # meta.dt is set by EventGate and is more trustable than dt, which after
            # migration to EventGate is set by the client.
            'camus.message.timestamp.field' => 'meta.dt,dt',
            'mapred.map.tasks'              => '1',
        },
        # Don't need to write _IMPORTED flags for EventLogging data
        check_dry_run    => true,
        # Only check these topic, since they should have data every hour.
        check_java_opts  => '-Dkafka.whitelist.topics=eventlogging_NavigationTiming',
        interval         => '*-*-* *:05:00',
    }


    # Shortcut for declaring a camus job that imports streams from specific event services.
    # We want separate camus jobs for each event service as their throughput volume can
    # vary significantly, and we don't want high volume topics to starve out small ones.
    # See also:
    # https://wikitech.wikimedia.org/wiki/Event_Platform/EventGate#EventGate_clusters
    $event_service_jobs = {
        'eventgate-analytics' => {
            'camus_properties' =>  {
                'etl.destination.path'          => "hdfs://${hadoop_cluster_name}/wmf/data/raw/event",
                'camus.message.timestamp.field' => 'meta.dt',
                'mapreduce.job.queuename'       => 'essential',
                # Set this to at least the number of topic-partitions you will be importing.
                'mapred.map.tasks'              => '1',
                'eventstreamconfig.uri'         => 'https://meta.wikimedia.org/w/api.php',
                # Here we explicitly restrict this test camus job to import only the test.event stream for eventgate-analytics.
                'eventstreamconfig.stream_names' => 'eventgate-analytics.test.event',
                'eventstreamconfig.settings_filters' => 'destination_event_service:eventgate-analytics',
            },
            # Add settings_filters to only check topics that have canary_events_enabled.
            # Here, this won't make a differences since we also specify stream_names for the test job.
            # This is mostly testing that the check_java_opts override works properly.
            'check_java_opts' => '-Deventstreamconfig.settings_filters=destination_event_service:eventgate-analytics,canary_events_enabled:true',
            'interval' => '*-*-* *:15:00',
        },
        'eventgate-main' => {
            'camus_properties' =>  {
                'etl.destination.path'          => "hdfs://${hadoop_cluster_name}/wmf/data/raw/event",
                'camus.message.timestamp.field' => 'meta.dt',
                'mapreduce.job.queuename'       => 'essential',
                # Set this to at least the number of topic-partitions you will be importing.
                'mapred.map.tasks'              => '1',
                'eventstreamconfig.uri'         => 'https://meta.wikimedia.org/w/api.php',
                # Here we explicitly restrict this test camus job to import only the small
                # mediawiki.page-delete stream for eventgate-main.
                'eventstreamconfig.stream_names' => 'mediawiki.page-delete',
                'eventstreamconfig.settings_filters' => 'destination_event_service:eventgate-main',
            },
            # Add settings_filters to only check topics that have canary_events_enabled.
            # Here, this won't make a differences since we also specify stream_names for the test job.
            # This is mostly testing that the check_java_opts override works properly.
            'check_java_opts' => '-Deventstreamconfig.settings_filters=destination_event_service:eventgate-main,canary_events_enabled:true',
            'interval' => '*-*-* *:16:00',
        },
    }

    # Declare each of the $event_service_jobs.
    $event_service_jobs.each |String $event_service_name, Hash $parameters| {
        #
        camus::job { "${event_service_name}_events":
            ensure           => 'absent',
            camus_properties => $parameters['camus_properties'],
            # Don't need to write _IMPORTED flags for event data
            check_dry_run    => true,
            check_java_opts  => $parameters['check_java_opts'],
            interval         => $parameters['interval'],
        }
    }
}
