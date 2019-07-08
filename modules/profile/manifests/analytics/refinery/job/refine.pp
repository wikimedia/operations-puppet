# == Class profile::analytics::refinery::job::refine
# Install cron jobs for Spark Refine jobs.  These jobs
# transform data imported into Hadoop into augmented Parquet backed
# Hive tables.
#
class profile::analytics::refinery::job::refine {
    require ::profile::analytics::refinery
    require ::profile::hive::client

    # Update this when you want to change the version of the refinery job jar
    # being used for the refine job.
    $refinery_version = '0.0.92'

    # Use this value by default
    Profile::Analytics::Refinery::Job::Refine_job {
        # Use this value as default refinery_job_jar.
        refinery_job_jar => "${::profile::analytics::refinery::path}/artifacts/org/wikimedia/analytics/refinery/refinery-job-${refinery_version}.jar"
    }

    # These configs will be used for all refine jobs unless otherwise overridden.
    $default_config = {
        'to_emails'           => 'analytics-alerts@wikimedia.org',
        'should_email_report' => true,
        'database'            => 'event',
        'output_path'         => '/wmf/data/event',
        'hive_server_url'     => "${::profile::hive::client::hiveserver_host}:${::profile::hive::client::hiveserver_port}",
        # Look for data to refine from 26 hours ago to 2 hours ago, giving some time for
        # raw data to be imported in the last hour or 2 before attempting refine.
        'since'               => '26',
        'until'               => '2',
    }

    # Refine EventLogging Analytics (capsule based) data.
    profile::analytics::refinery::job::refine_job { 'eventlogging_analytics':
        job_config       => merge($default_config, {
            input_path                      => '/wmf/data/raw/eventlogging',
            input_path_regex                => 'eventlogging_(.+)/hourly/(\\d+)/(\\d+)/(\\d+)/(\\d+)',
            input_path_regex_capture_groups => 'table,year,month,day,hour',
            table_blacklist_regex           => '^Edit|ChangesListHighlights|InputDeviceDynamics|PageIssues$',
            # Deduplicate basd on uuid field and geocode ip in EventLogging analytics data.
            transform_functions             => 'org.wikimedia.analytics.refinery.job.refine.filter_out_non_wiki_hostname,org.wikimedia.analytics.refinery.job.refine.deduplicate_eventlogging,org.wikimedia.analytics.refinery.job.refine.geocode_ip',
            # Get EventLogging JSONSchemas from meta.wikimedia.org.
            schema_base_uri                 => 'eventlogging',
        }),
        # Use webproxy so that this job can access meta.wikimedia.org to retrive JSONSchemas.
        spark_extra_opts => '--driver-java-options=\'-Dhttp.proxyHost=webproxy.eqiad.wmnet -Dhttp.proxyPort=8080 -Dhttps.proxyHost=webproxy.eqiad.wmnet -Dhttps.proxyPort=8080\'',
        interval         => '*-*-* *:30:00',
    }


    # Refine EventBus data.
    # TODO: deprecate this job in favor of the mediawiki_events job;
    # need to make sure JSONSchemas are compatible with existing Hive table schemas.
    $eventbus_tables = [
        'mediawiki_revision_create',
        'mediawiki_revision_score',
        'mediawiki_revision_visibility_change',
        'resource_change',
    ]
    $eventbus_table_whitelist_regex = "^(${join($eventbus_tables, '|')})$"
    profile::analytics::refinery::job::refine_job { 'eventlogging_eventbus':
        job_config => merge($default_config, {
            input_path                      => '/wmf/data/raw/event',
            input_path_regex                => '.*(eqiad|codfw)_(.+)/hourly/(\\d+)/(\\d+)/(\\d+)/(\\d+)',
            input_path_regex_capture_groups => 'datacenter,table,year,month,day,hour',
            # Strict whitelist for this refine_job while we migrate from this schema inference baesd
            # job to the JSONSchema based one below.  These match all tables refined by this
            # job as of 2019-04-19.  This excludes mediawiki_page_properties_change and
            # mediawiki_recentchange since those don't have a strong enough schema.
            table_whitelist_regex           => $eventbus_table_whitelist_regex,
            # Deduplicate eventbus based data based on meta.id field
            transform_functions             => 'org.wikimedia.analytics.refinery.job.refine.deduplicate_eventbus',
        }),
        interval   => '*-*-* *:40:00',
    }

    # List of mediawiki event tables to refine.
    # Not all event tables are in this list, as some are not refineable.
    # E.g. mediawiki_page_properties_change has freeform type: object fields.
    $mediawiki_event_tables = [
        'mediawiki_api_request',
        'mediawiki_cirrussearch_request',
        'mediawiki_page_create',
        'mediawiki_page_delete',
        'mediawiki_page_links_change',
        'mediawiki_page_move',
        'mediawiki_page_restrictions_change',
        'mediawiki_page_undelete',
        'mediawiki_revision_tags_change',
        'mediawiki_user_blocks_change',

    ]
    $mediawiki_event_table_whitelist_regex = "^(${join($mediawiki_event_tables, '|')})$"

    # Refine Mediawiki event data.
    # This will replace the eventlogging_eventbus job above.
    profile::analytics::refinery::job::refine_job { 'mediawiki_events':
        job_config => merge($default_config, {
            input_path                      => '/wmf/data/raw/event',
            input_path_regex                => '.*(eqiad|codfw)_(.+)/hourly/(\\d+)/(\\d+)/(\\d+)/(\\d+)',
            input_path_regex_capture_groups => 'datacenter,table,year,month,day,hour',
            table_whitelist_regex           => $mediawiki_event_table_whitelist_regex,
            # Deduplicate eventbus based data based on meta.id field
            transform_functions             => 'org.wikimedia.analytics.refinery.job.refine.deduplicate_eventbus',
            # Get JSONSchemas from the HTTP schema service.
            # Schema URIs are extracted from the $schema field in each event.
            schema_base_uri                 => "http://schema.svc.${::site}.wmnet:8190/repositories/mediawiki/jsonschema",
        }),
        interval   => '*-*-* *:20:00',
    }


    # $problematic_jobs will not be refined.
    # These have inconsistent schemas that cause refinement to fail.
    $problematic_jobs = [
        'EchoNotificationJob',
        'EchoNotificationDeleteJob',
        'TranslationsUpdateJob',
        'MessageGroupStatesUpdaterJob',
        'InjectRCRecords',
        'cirrusSearchDeleteArchive',
        'enqueue',
        'htmlCacheUpdate',
        'LocalRenameUserJob',
        'RecordLintJob',
        'wikibase_addUsagesForPage',
        'refreshLinks',
        'cirrusSearchCheckerJob',
        'MassMessageSubmitJob',
        'refreshLinksPrioritized',
        'TranslatablePageMoveJob',
        'ORESFetchScoreJob',
        'PublishStashedFile',
        'CentralAuthCreateLocalAccountJob',
        'gwtoolsetUploadMediafileJob',
        'gwtoolsetUploadMetadataJob',
    ]
    $job_table_blacklist = sprintf('.*(%s)$', join($problematic_jobs, '|'))

    profile::analytics::refinery::job::refine_job { 'eventlogging_eventbus_job_queue':
        job_config => merge($default_config, {
            input_path                      => '/wmf/data/raw/mediawiki_job',
            input_path_regex                => '.*(eqiad|codfw)_(.+)/hourly/(\\d+)/(\\d+)/(\\d+)/(\\d+)',
            input_path_regex_capture_groups => 'datacenter,table,year,month,day,hour',
            table_blacklist_regex           => $job_table_blacklist,
            # Deduplicate eventbus based data based on meta.id field
            transform_functions             => 'org.wikimedia.analytics.refinery.job.refine.deduplicate_eventbus',
        }),
        interval   => '*-*-* *:25:00',
    }

    # Netflow data
    profile::analytics::refinery::job::refine_job { 'netflow':
        job_config             => merge($default_config, {
            # This is imported by camus_job { 'netflow': }
            input_path                      => '/wmf/data/raw/netflow',
            input_path_regex                => '(netflow)/hourly/(\\d+)/(\\d+)/(\\d+)/(\\d+)',
            input_path_regex_capture_groups => 'table,year,month,day,hour',
            output_path                     => '/wmf/data/wmf',
            database                        => 'wmf',
        }),
        interval               => '*-*-* *:45:00',
        monitoring_enabled     => false,
        refine_monitor_enabled => false,
    }
}
