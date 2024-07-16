# SPDX-License-Identifier: Apache-2.0
# Class: profile::analytics::refinery::job::canary_events
#
# Installs a systemd timer that produces canary events for all streams that have
# canary_events_enabled:true configured to all event intake services.
#
# By producing canary events in to these streams, we can differentiate between streams and topics
# that have no data, and ones that have a broken produce pipeline.
#
class profile::analytics::refinery::job::canary_events(
    String $ensure_timers = lookup('profile::analytics::refinery::job::canary_events::ensure_timers', { 'default_value' => 'present' }),
) {

    require ::profile::analytics::refinery
    require ::profile::analytics::refinery::event_service_config

    # Update this when you want to change the version of the refinery job jar
    # being used for the job.
    $refinery_version = '0.2.44'
    $refinery_job_jar = "${::profile::analytics::refinery::path}/artifacts/org/wikimedia/analytics/refinery/refinery-job-${refinery_version}-shaded.jar"

    $event_intake_service_url_config_file = $::profile::analytics::refinery::event_service_config::event_intake_service_url_config_file

    # NOTE: ProduceCanaryEvents is not a Spark job!  However,
    # it is written in Scala, and we don't have a deployment of
    # Scala dependencies anywhere except for with Spark.
    # We use spark3-submit here to launch the job.  No Spark session
    # is ever instatiated, so effectively this just runs the this
    # as a JVM job using the Scala dependences provided by our
    # Spark distribution.
    profile::analytics::refinery::job::spark_job { 'produce_canary_events':
        ensure     => $ensure_timers,
        jar        => $refinery_job_jar,
        main_class => 'org.wikimedia.analytics.refinery.job.ProduceCanaryEvents',
        job_opts   => [
            # Only produce canary events for streams that have canary_events_enabled: true
            '--settings_filters=canary_events_enabled:true',
            # Get schemas fro m internal schema.discovery.wmnet base URIs.
            '--schema_base_uris=https://schema.discovery.wmnet/repositories/primary/jsonschema,https://schema.discovery.wmnet/repositories/secondary/jsonschema',
            # Get stream config from MediaWiki EventStreamConfig API.
            '--event_stream_config_uri=https://meta.wikimedia.org/w/api.php',
            # Read in event service name to URL mapping from this.
            "--event_service_config_uri=file://${event_intake_service_url_config_file}",
            # Actually produce canary events.
            '--dry_run=false',
        ],
        interval   => '*-*-* *:00/15:00',
    }

}
