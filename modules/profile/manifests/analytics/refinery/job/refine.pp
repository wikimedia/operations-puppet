# SPDX-License-Identifier: Apache-2.0
# == Class profile::analytics::refinery::job::refine
# Install cron jobs for Spark Refine jobs.  These jobs
# transform data imported into Hadoop into augmented Parquet backed
# Hive tables.
#
# Description of Refine jobs declared here:
#
# - event
#   Uses schemas from schema.discovery.wmnet and refines from
#   /wmf/data/raw/event -> /wmf/data/event into the Hive event database.
#
# - eventlogging_legacy
#   Uses schemas from schema.discovery.wmnet and refines from
#   /wmf/data/raw/eventlogging -> /wmf/data/event into the Hive event database.
#   This job is used for EventLogging legacy streams that have been migrated to EventGate.
#
# - eventlogging_analytics
#   Uses schemas from meta.wikimedia.org and refines from
#   /wmf/data/raw/eventlogging -> /wmf/data/event into the Hive event database.
#   This job is being phased out and is used for EventLogging legacy streams
#   that have not been migrated to EventGate.
#
# - netflow
#   Infers schema from data and refines from
#   /wmf/data/raw/netflow -> /wmf/data/event/netflow in the Hive event database.
#   Requires a network infra config file.
#
class profile::analytics::refinery::job::refine(
    Wmflib::Ensure $ensure_timers = lookup('profile::analytics::refinery::job::refine::ensure_timers', { 'default_value' => 'present' }),
    Boolean $use_kerberos_keytab  = lookup('profile::analytics::refinery::job::refine::use_kerberos_keytab', { 'default_value' => true }),
) {
    require ::profile::analytics::refinery
    require ::profile::hive::client
    require ::profile::analytics::refinery::network_region_config

    # Update this when you want to change the version of the refinery job jar
    # being used for the refine job.
    $refinery_version = '0.2.49'

    # Use this value by default
    Profile::Analytics::Refinery::Job::Refine_job {
        # Use this value as default refinery_job_jar.
        refinery_job_jar => "${::profile::analytics::refinery::path}/artifacts/org/wikimedia/analytics/refinery/refinery-job-${refinery_version}-shaded.jar",
        # Production refine jobs can use a lot of memory, especially for larger datasets.
        # We choose to use 4 cores with lots of executor memory and extra memoryOverhead to
        # reduce JVM container overhead.  Each executor can run more tasks in parallel
        # and use more memory.  Having 4 cores sharing more memory accounts for the fact
        # that some tasks are very small and some are large.  This allows large tasks to
        # use more of the memory pool for the executor and smaller ones to use less, hopefully
        # making better use of all allocated memory across the cluster.
        spark_max_executors   => 64,
        spark_executor_memory => '16G',
        spark_executor_cores  => 4,
        spark_extra_opts      => '--conf spark.executor.memoryOverhead=4096',
    }

    # These configs will be used for all refine jobs unless otherwise overridden.
    $default_config = {
        'to_emails'                          => 'data-engineering-alerts@wikimedia.org',
        'from_email'                         => 'Refinery <noreply@wikimedia.org>',
        'should_email_report'                => true,
        'smtp_uri'                           => 'localhost:25',
        'output_database'                    => 'event',
        'output_path'                        => '/wmf/data/event',
        'hive_server_url'                    => "${::profile::hive::client::hiveserver_host}:${::profile::hive::client::hiveserver_port}",
        # Look for data to refine from 26 hours ago to 2 hours ago, giving some time for
        # raw data to be imported in the last hour or 2 before attempting refine.
        'since'                              => '26',
        'until'                              => '2',
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
    $event_input_path = '/wmf/data/raw/event'
    $event_input_path_regex = "${event_input_path}/(eqiad|codfw)\\.(.+)/${hive_hourly_path_regex}"
    $event_input_path_regex_capture_groups = "datacenter,table,${hive_hourly_path_regex_capture_groups}"
    # Unrefineable tables due to poorly defined schemas.
    $event_table_exclude_list = [
        # TODO: include page_properties_change after https://phabricator.wikimedia.org/T281483 is fixed.
        'mediawiki_page_properties_change',
        'mediawiki_recentchange',
        # Cannot be refined until https://gerrit.wikimedia.org/r/c/operations/deployment-charts/+/620008 is deployed
        'resource_purge',
    ]
    $event_table_exclude_regex = "^(${join($event_table_exclude_list, '|')})$"

    profile::analytics::refinery::job::refine_job { 'event':
        ensure           => $ensure_timers,
        job_config       => merge($default_config, {
            input_path                      => $event_input_path,
            input_path_regex                => $event_input_path_regex,
            input_path_regex_capture_groups => $event_input_path_regex_capture_groups,
            input_path_datetime_format      => $hive_input_path_datetime_format,
            table_exclude_regex             => $event_table_exclude_regex,
            # event_transforms:
            # - deduplicate
            # - geocode_ip
            # - parse_user_agent
            transform_functions             => 'org.wikimedia.analytics.refinery.job.refine.event_transforms',
            # Get JSONSchemas from the HTTP schema service.
            # Schema URIs are extracted from the $schema field in each event.
            schema_base_uris                => $schema_base_uris,
            # Set max parallelism to 64.  This is the max number of Refines that can run at once.
            # This will only be reached if there are at least this many tables to refine.
            # Each table is refined in serial.  I.e. if there are 10 hours for a given table,
            # each of those will be launched in serial in the same thread.
            parallelism                     => 64,
        }),
        interval         => '*-*-* *:20:00',
        monitor_interval => '*-*-* 01:15:00',
        use_keytab       => $use_kerberos_keytab,
    }



    # === EventLogging Legacy data ===
    # /wmf/data/raw/eventlogging -> /wmf/data/event
    #
    # We are beginning the process of migrating legacy EventLogging events to EventGate
    # and making them forward compatible with Event Platform schemas.  Once they go through
    # EventGate, these events will _almost_ look exactly like the ones refined by the
    # event refine_job defined above.  The main difference is that they aren't (yet) using
    # datacenter topic prefixes.  If we ever make them start using topic prefixes, we can
    # merge this refine job into the regular 'event' one.
    $eventlogging_legacy_input_path = '/wmf/data/raw/eventlogging_legacy'
    $eventlogging_legacy_input_path_regex = "${eventlogging_legacy_input_path}/eventlogging_(.+)/${hive_hourly_path_regex}"
    $eventlogging_legacy_input_path_regex_capture_groups = "table,${hive_hourly_path_regex_capture_groups}"

    # While we migrate we will use an explicit include list of
    # EventLogging streams that have been migrated to EventGate.
    $eventlogging_legacy_table_include_list = [
        'ContentTranslationAbuseFilter',
        'DesktopWebUIActionsTracking',
        'MobileWebUIActionsTracking',
        'PrefUpdate',
        'QuickSurveyInitiation',
        'QuickSurveysResponses',
        'SearchSatisfaction',
        'SpecialInvestigate',
        'TemplateWizard',
        'Test',
        'UniversalLanguageSelector',
        'WikidataCompletionSearchClicks',

        # Editing team schemas
        'EditAttemptStep',
        'VisualEditorFeatureUse',

        # Growth team schemas
        'HelpPanel',
        'HomepageModule',
        'NewcomerTask',
        'HomepageVisit',
        'ServerSideAccountCreation',

        # NavigationTiming extension legacy schemas
        'CpuBenchmark',
        'NavigationTiming',
        'PaintTiming',
        'SaveTiming',

        # WMDE Technical Wishes team schemas
        'CodeMirrorUsage',
        'ReferencePreviewsBaseline',
        'ReferencePreviewsCite',
        'ReferencePreviewsPopups',
        'TemplateDataApi',
        'TemplateDataEditor',
        'TwoColConflictConflict',
        'TwoColConflictExit',
        'VirtualPageView',
        'VisualEditorTemplateDialogUse',
        'WikibaseTermboxInteraction',
        'WMDEBannerEvents',
        'WMDEBannerInteractions',
        'WMDEBannerSizeIssue',

        # FR Tech schemas
        'LandingPageImpression',
        'CentralNoticeBannerHistory',
        'CentralNoticeImpression',

        # TranslationRecommendation schemas
        'TranslationRecommendationUserAction',
        'TranslationRecommendationUIRequests',
        'TranslationRecommendationAPIRequests',

        # Readers Web schemas
        'WikipediaPortal',
    ]
    $eventlogging_legacy_table_include_regex = downcase("^(${join($eventlogging_legacy_table_include_list, '|')})$")

    $eventlogging_legacy_table_exclude_list = [
        # Legacy EventLogging tables to exclude from Refinement.
        'Edit',
        'InputDeviceDynamics',
        'PageIssues',
        'MobileWebMainMenuClickTracking',
        'KaiOSAppConsent',
        'MobileWebUIClickTracking',
        'CitationUsagePageLoad', # Schema is deleted.
        'CitationUsage',         # Schema is deleted.
        'ReadingDepth',          # Schema is deleted.
        'EditConflict',          # Schema is deleted.
        'ResourceTiming',        # Schema is deleted.
        'RUMSpeedIndex',         # Schema is deleted.
        'LayoutShift',           # Schema is deleted.
        'FeaturePolicyViolation', # Instrumentation has been removed: https://phabricator.wikimedia.org/T209572#8774403
        'SpecialMuteSubmit',      # Instrumentation has been removed: https://phabricator.wikimedia.org/T329718
        'SuggestedTagsAction',   # Extension generating the event is being sunsetted: https://phabricator.wikimedia.org/T352884
    ]
    $eventlogging_legacy_table_exclude_regex = downcase("^(${join($eventlogging_legacy_table_exclude_list, '|')})$")

    # Since EventLogging legacy data comes from external clients,
    # non wikimedia domains and other unwanted domains have always been filtered out.
    $eventlogging_legacy_transform_functions = 'org.wikimedia.analytics.refinery.job.refine.filter_allowed_domains,org.wikimedia.analytics.refinery.job.refine.event_transforms'

    profile::analytics::refinery::job::refine_job { 'eventlogging_legacy':
        ensure           => $ensure_timers,
        job_config       => merge($default_config, {
            input_path                      => $eventlogging_legacy_input_path,
            input_path_regex                => $eventlogging_legacy_input_path_regex,
            input_path_regex_capture_groups => $eventlogging_legacy_input_path_regex_capture_groups,
            input_path_datetime_format      => $hive_input_path_datetime_format,
            table_include_regex             => $eventlogging_legacy_table_include_regex,
            table_exclude_regex             => $eventlogging_legacy_table_exclude_regex,
            transform_functions             => $eventlogging_legacy_transform_functions,
            # Get JSONSchemas from the HTTP schema service.
            # Schema URIs are extracted from the $schema field in each event.
            schema_base_uris                => $schema_base_uris,

        }),
        interval         => '*-*-* *:25:00',
        monitor_interval => '*-*-* 00:30:00',
        use_keytab       => $use_kerberos_keytab,
    }


    # === EventLogging Analytics (capsule based) data ===
    # /wmf/data/raw/eventlogging -> /wmf/data/event
    # This job is being phased out in favor of the eventlogging_legacy one defined above.
    $eventlogging_analytics_input_path = '/wmf/data/raw/eventlogging_legacy'
    $eventlogging_analytics_input_path_regex = "${eventlogging_analytics_input_path}/eventlogging_(.+)/${hive_hourly_path_regex}"
    $eventlogging_analytics_input_path_regex_capture_groups = "table,${hive_hourly_path_regex_capture_groups}"

    # As of 2024-09, the only remaining non migrated eventlogging legacy stream is
    # eventlogging_MediaWikiPingback.
    # Manually set the table_include_regex to only refine the mediawikipingback table.
    $eventlogging_analytics_table_include_regex = '^mediawikipingback$'

    profile::analytics::refinery::job::refine_job { 'eventlogging_analytics':
        ensure           => $ensure_timers,
        job_config       => merge($default_config, {
            input_path                      => $eventlogging_analytics_input_path,
            input_path_regex                => $eventlogging_analytics_input_path_regex,
            input_path_regex_capture_groups => $eventlogging_analytics_input_path_regex_capture_groups,
            input_path_datetime_format      => $hive_input_path_datetime_format,
            table_include_regex             => $eventlogging_analytics_table_include_regex,
            transform_functions             => $eventlogging_legacy_transform_functions,
            # Get EventLogging JSONSchemas from meta.wikimedia.org.
            schema_base_uris                => 'eventlogging',
        }),
        interval         => '*-*-* *:30:00',
        monitor_interval => '*-*-* 00:15:00',
        use_keytab       => $use_kerberos_keytab,
    }


    # === Netflow data ===
    # /wmf/data/raw/netflow -> /wmf/data/event
    $netflow_input_path = '/wmf/data/raw/netflow'
    $netflow_input_path_regex = "${netflow_input_path}/([^/]+)/${hive_hourly_path_regex}"
    $netflow_input_path_regex_capture_groups = "table,${hive_hourly_path_regex_capture_groups}"

    profile::analytics::refinery::job::refine_job { 'netflow':
        ensure                 => $ensure_timers,
        job_config             => merge($default_config, {
            input_path                      => $netflow_input_path,
            input_path_regex                => $netflow_input_path_regex,
            input_path_regex_capture_groups => $netflow_input_path_regex_capture_groups,
            input_path_datetime_format      => $hive_input_path_datetime_format,
            transform_functions             => 'org.wikimedia.analytics.refinery.job.refine.augment_netflow',
        }),
        # augment_netflow needs this to add network region / DC information.
        spark_extra_files      => $::profile::analytics::refinery::network_region_config::network_region_config_file,
        refine_monitor_enabled => true,
        interval               => '*-*-* *:45:00',
        monitor_interval       => '*-*-* 03:45:00',
        use_keytab             => $use_kerberos_keytab,
    }

}
