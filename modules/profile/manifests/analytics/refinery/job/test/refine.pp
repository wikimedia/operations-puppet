# SPDX-License-Identifier: Apache-2.0
# == Class profile::analytics::refinery::job::test::refine
#
# Install cron jobs for Spark Refine jobs.  These jobs
# transform data imported into Hadoop into augmented Parquet backed
# Hive tables.
#
# This version is only for the Hadoop testing cluster
#
class profile::analytics::refinery::job::test::refine (
    Wmflib::Ensure $ensure_timers = lookup('profile::analytics::refinery::job::test::refine::ensure_timers', { 'default_value' => 'present' }),
    Boolean $use_kerberos_keytab  = lookup('profile::analytics::refinery::job::test::refine::use_kerberos_keytab', { 'default_value' => true }),
) {
    require ::profile::analytics::refinery
    require ::profile::hive::client

    # Update this when you want to change the version of the refinery job jar
    # being used for the refine job.
    $refinery_version = '0.2.49'

    # Use this value by default
    Profile::Analytics::Refinery::Job::Refine_job {
        # Use this value as default refinery_job_jar.
        refinery_job_jar => "${::profile::analytics::refinery::path}/artifacts/org/wikimedia/analytics/refinery/refinery-job-${refinery_version}-shaded.jar",
    }

    # These configs will be used for all refine jobs unless otherwise overridden.
    $default_config = {
        'to_emails'           => 'data-engineering-alerts@wikimedia.org',
        'from_email'          => 'Refinery <noreply@wikimedia.org>',
        'should_email_report' => true,
        'output_database'     => 'event',
        'output_path'         => '/wmf/data/event',
        # Look for data to refine from 26 hours ago to 2 hours ago, giving some time for
        # raw data to be imported in the last hour or 2 before attempting refine.
        'since'               => '26',
        'until'               => '2',
        # Until T259924 is fixed, we MUST merge with Hive schema before reading JSON data.
        'merge_with_hive_schema_before_read' => true,
    }

    # Conventional Hive format path with partition keys (used by Gobblin), i.e. year=yyyy/month=mm/day=dd/hour=hh.
    $hive_hourly_path_regex = 'year=(\\d+)/month=(\\d+)/day=(\\d+)/hour=(\\d+)'
    $hive_hourly_path_regex_capture_groups = 'year,month,day,hour'
    # Used by Java time formats to find potential hourly paths to refine.
    $hive_input_path_datetime_format = '\'year=\'yyyy/\'month=\'MM/\'day=\'dd/\'hour=\'HH'

    # URIs from which to look up event schemas. (not all refine jobs use this).
    $schema_base_uris = 'https://schema.discovery.wmnet/repositories/primary/jsonschema/,https://schema.discovery.wmnet/repositories/secondary/jsonschema/'


    # === Event data ===
    # /wmf/data/raw/event -> /wmf/data/event
    # NOTE: refinery::job::test::gobblin only imports limited data in test cluster,
    # so we don't need to specify any table include or exclude regexes.
    $event_input_path = '/wmf/data/raw/event'
    $event_input_path_regex = "${event_input_path}/(eqiad|codfw)\\.(.+)/${hive_hourly_path_regex}"
    $event_input_path_regex_capture_groups = "datacenter,table,${hive_hourly_path_regex_capture_groups}"
    profile::analytics::refinery::job::refine_job { 'event_test':
        ensure           => $ensure_timers,
        job_config       => merge($default_config, {
            input_path                      => $event_input_path,
            input_path_regex                => $event_input_path_regex,
            input_path_regex_capture_groups => $event_input_path_regex_capture_groups,
            input_path_datetime_format      => $hive_input_path_datetime_format,
            transform_functions             => 'org.wikimedia.analytics.refinery.job.refine.event_transforms',
            # Get JSONSchemas from the HTTP schema service.
            # Schema URIs are extracted from the $schema field in each event.
            schema_base_uris                => $schema_base_uris,
        }),
        interval         => '*-*-* *:20:00',
        monitor_interval => '*-*-* 01:15:00',
        use_keytab       => $use_kerberos_keytab,
    }

    # === EventLogging Legacy data ===
    # /wmf/data/raw/eventlogging_legacy -> /wmf/data/event
    # EventLogging legacy events migrated to Event Platform.
    $eventlogging_legacy_input_path = '/wmf/data/raw/eventlogging_legacy'
    # NOTE: We need to prefix our partition discovery regex with the input_path here,
    # since eventlogging_legacy would match eventlogging_(.+) without it.
    $eventlogging_legacy_input_path_regex = "${eventlogging_legacy_input_path}/eventlogging_(.+)/${hive_hourly_path_regex}"
    $eventlogging_legacy_input_path_regex_capture_groups = "table,${hive_hourly_path_regex_capture_groups}"
    profile::analytics::refinery::job::refine_job { 'eventlogging_legacy_test':
        ensure           => $ensure_timers,
        job_config       => merge($default_config, {
            input_path                      => $eventlogging_legacy_input_path,
            input_path_regex                => $eventlogging_legacy_input_path_regex,
            input_path_regex_capture_groups => $eventlogging_legacy_input_path_regex_capture_groups,
            input_path_datetime_format      => $hive_input_path_datetime_format,
            # Since EventLogging legacy data comes from external clients,
            # non wikimedia domains and other unwanted domains have always been filtered out.
            transform_functions             => 'org.wikimedia.analytics.refinery.job.refine.filter_allowed_domains,org.wikimedia.analytics.refinery.job.refine.event_transforms',
            # Get JSONSchemas from the HTTP schema service.
            # Schema URIs are extracted from the $schema field in each event.
            schema_base_uris                => $schema_base_uris,
        }),
        interval         => '*-*-* *:25:00',
        monitor_interval => '*-*-* 00:30:00',
        use_keytab       => $use_kerberos_keytab,
    }


}
