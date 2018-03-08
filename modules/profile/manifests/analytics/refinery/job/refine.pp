# == Class profile::analytics::refinery::job::efine
# Install cron jobs for Spark Refine jobs.  These jobs
# refine JSON data imported in Hadoop into Parquet backed
# Hive tables.
#
class profile::analytics::refinery::job::refine {
    require ::profile::analytics::refinery

    # update this when you want to change the version of the refinery job jar
    # being used for the refine job.
    $refinery_version = '0.0.59'
    # Use this value by default
    Profile::Analytics::Refinery::Job::Json_refine_job {
        # Use this value as default refinery_job_jar.
        refinery_job_jar => "${::profile::analytics::refinery::path}/artifacts/org/wikimedia/analytics/refinery/refinery-job-${refinery_version}.jar"
    }

    # Refine EventLogging Analytics (capsule based) data.
    profile::analytics::refinery::job::refine_job { 'eventlogging_analytics':
        input_base_path     => '/wmf/data/raw/eventlogging',
        input_regex         => 'eventlogging_(.+)/hourly/(\\d+)/(\\d+)/(\\d+)/(\\d+)',
        input_capture       => 'table,year,month,day,hour',
        output_base_path    => '/wmf/data/event',
        output_database     => 'event',
        table_blacklist     => '^Edit|ChangesListHighlights$',
        # Deduplicate basd on uuid field and geocode ip in EventLogging analytics data.
        transform_functions => 'org.wikimedia.analytics.refinery.job.refine.deduplicate_eventlogging,org.wikimedia.analytics.refinery.job.refine.geocode_ip',
        minute              => 30,
    }

    # Refine EventBus data.
    profile::analytics::refinery::job::refine_job { 'eventlogging_eventbus':
        input_base_path     => '/wmf/data/raw/event',
        # 'datacenter' is extracted from the input path into a Hive table partition
        input_regex         => '.*(eqiad|codfw)_(.+)/hourly/(\\d+)/(\\d+)/(\\d+)/(\\d+)',
        input_capture       => 'datacenter,table,year,month,day,hour',
        output_base_path    => '/wmf/data/event',
        output_database     => 'event',
        table_blacklist     => '^mediawiki_page_properties_change|mediawiki_recentchange$',
        # Deduplicate eventbus based data based on meta.id field
        transform_functions => 'org.wikimedia.analytics.refinery.job.refine.deduplicate_eventbus',
        minute              => 20,
    }

    # Refine Mediawiki job queue events (from EventBus).
    # This could be combined into the same EventBus refine job above, but it is nice to
    # have them separated, as the job queue schemas are legacy and can be problematic.

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
    $table_blacklist = sprintf('.*(%s)$', join($problematic_jobs, '|'))

    profile::analytics::refinery::job::refine_job { 'eventlogging_eventbus_job_queue':
        # This is imported by camus_job { 'mediawiki_job': }
        input_base_path     => '/wmf/data/raw/mediawiki_job',
        # 'datacenter' is extracted from the input path into a Hive table partition
        input_regex         => '.*(eqiad|codfw)_(.+)/hourly/(\\d+)/(\\d+)/(\\d+)/(\\d+)',
        input_capture       => 'datacenter,table,year,month,day,hour',
        output_base_path    => '/wmf/data/event',
        output_database     => 'event',
        table_blacklist     => $table_blacklist,
        # Deduplicate eventbus based data based on meta.id field
        transform_functions => 'org.wikimedia.analytics.refinery.job.refine.deduplicate_eventbus',
        minute              => 25,
    }

    # Netflow data
    profile::analytics::refinery::job::refine_job { 'netflow':
        # This is imported by camus_job { 'netflow': }
        input_base_path  => '/wmf/data/raw/netflow',
        input_regex      => '(netflow)/hourly/(\\d+)/(\\d+)/(\\d+)/(\\d+)',
        input_capture    => 'table,year,month,day,hour',
        output_base_path => '/wmf/data/wmf',
        output_database  => 'wmf',
        minute           => 45,
    }
}
