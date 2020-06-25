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
#   Ingests eventlogging_.+ topics into /wmf/data/raw/eventlogging/.
#
# - event_dynamic_stream_config
#   Ingests topics belonging to all streams defined in MediaWiki Config
#   via the EventStreamConfig MediaWiki Extension API.  A list of active streams
#   is requested from the MW API at job launch time, and a list of topics
#   to ingest is built from that.  These topics are ingested into
#   /wmf/data/raw/event/.  Because eventlogging_.+ topics are not prefixed
#   with the datacenter name (eqiad|codfw), they are explicitly blacklisted,
#   even if they are in stream config.
#
# - mediawiki_events
#   Ingests whitelisted mediawiki.*  (non job) events into /wmf/data/raw/event/.
#
# - mediawiki_analytics_events
#   Ingests high volume whitelistsed mediawiki._ (non job) events into
#   /wmf/data/raw/event.  This exists separately from mediawiki_events to keep long
#   running high volume topic imports from starving out smaller volume ones.
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

    # Import eventlogging_* topics into /wmf/data/raw/eventlogging
    # once every hour.
    camus::job { 'eventlogging':
        camus_properties      => {
            'kafka.whitelist.topics'        => '^eventlogging_.+',
            'camus.message.timestamp.field' => 'dt',
            # Set this to at least the number of topic/partitions you will be importing.
            'mapred.map.tasks'              => '100',
        },
        # Don't need to write _IMPORTED flags for EventLogging data
        check_dry_run         => true,
        # Only check these topic, since they should have data every hour.
        check_topic_whitelist => '^eventlogging_(NavigationTiming|VirtualPageView)',
        interval              => '*-*-* *:05:00',
    }

    # Imports active stream topics defined in MediaWiki config wgEventStreams
    # into /wmf/data/raw/event.
    camus::job { 'event_dynamic_stream_configs':
        camus_properties       => {
            # Write these into the /wmf/data/raw/event directory
            'etl.destination.path'          => "hdfs://${hadoop_cluster_name}/wmf/data/raw/event",
            'camus.message.timestamp.field' => 'meta.dt',
            # Set this to at least the number of topic/partitions you will be importing.
            'mapred.map.tasks'              => '10',
            # make sure we don't import any dynamically configured
            # eventlogging_* topics. These are handled by the
            # eventlogging Camus job declared above.
            'kafka.blacklist.topics'        => '^eventlogging_.*'
        },
        # Build kafka.whitelist.topics using EventStreamConfig API.
        dynamic_stream_configs => true,
        # Don't need to write _IMPORTED flags for event data
        check_dry_run          => true,
        # Only check topics th at will have data every hour.
        check_topic_whitelist  => '(eqiad|codfw).test.event',
        interval               => '*-*-* *:30:00',
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


    # Imports MediaWiki (EventBus) events that are produced via eventgate-analytics
    # TODO: These are no longer all 'mediawiki' events.  Rename this job.
    # These are events that are produced by MediaWiki
    # to eventgate-analytics and into the Kafka Jumbo cluster.
    # They are relatively high volume compared to the other 'mediawiki_events'.
    camus::job { 'mediawiki_analytics_events':
        camus_properties      => {
            # Write these into the /wmf/data/raw/event directory
            'etl.destination.path'            => "hdfs://${hadoop_cluster_name}/wmf/data/raw/event",
            'kafka.whitelist.topics'          => '(eqiad|codfw)\.(mediawiki\.(api-request|cirrussearch-request)|.+\.sparql-query)',
            'camus.message.timestamp.field'   => 'meta.dt',
            # Set this to at least the number of topic/partitions you will be importing.
            'mapred.map.tasks'                => '60',
            # This camus runs every 15 minutes, so limiting it to 14 should keep runs fresh.
            'kafka.max.pull.minutes.per.task' => '14',
        },
        # mediawiki_analytics_events has been reset so its 'camus_name' has changed from the default.
        # This is just used for the default path to the camus history files in HDFS.
        camus_name            => 'mediawiki_analytics_events-01',
        # Don't need to write _IMPORTED flags for event data
        check_dry_run         => true,
        # Only check high volume topics that will almost certainly have data every hour.
        check_topic_whitelist => "${primary_mediawiki_dc}.mediawiki.(api-request|cirrussearch-request)",
        interval              => '*-*-* *:00/15:00',
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
