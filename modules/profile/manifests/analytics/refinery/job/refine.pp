# == Class profile::analytics::refinery::job::refine
# Install cron jobs for Spark Refine jobs.  These jobs
# transform data imported into Hadoop into augmented Parquet backed
# Hive tables.
#
# [*deploy_jobs*]
#   Temporary flag to avoid deploying jobs on new hosts.
#   Default: true
#
class profile::analytics::refinery::job::refine (
    $deploy_jobs  = hiera('profile::analytics::refinery::job::refine::deploy_jobs', true),
){
    require ::profile::analytics::refinery
    require ::profile::hive::client

    # Update this when you want to change the version of the refinery job jar
    # being used for the refine job.
    $refinery_version = '0.0.83'

    # Use this value by default
    Profile::Analytics::Refinery::Job::Refine_job {
        # Use this value as default refinery_job_jar.
        refinery_job_jar => "${::profile::analytics::refinery::path}/artifacts/org/wikimedia/analytics/refinery/refinery-job-${refinery_version}.jar"
    }

    # These configs will be used for all refine jobs unless otherwise overridden.
    $default_config = {
        'emails_to'           => 'analytics-alerts@wikimedia.org',
        'should_email_report' => true,
        'database'            => 'event',
        'output_path'         => '/wmf/data/event',
        'hive_server_url'     => "${::profile::hive::client::hiveserver_host}:${::profile::hive::client::hiveserver_port}",
        # Look for data to refine from 26 hours ago to 2 hours ago, giving some time for
        # raw data to be imported in the last hour or 2 before attempting refine.
        'since'               => '26',
        'until'               => '2',
    }

    if $deploy_jobs {

        # Refine EventLogging Analytics (capsule based) data.
        profile::analytics::refinery::job::refine_job { 'eventlogging_analytics':
            job_config => merge($default_config, {
                input_path                      => '/wmf/data/raw/eventlogging',
                input_path_regex                => 'eventlogging_(.+)/hourly/(\\d+)/(\\d+)/(\\d+)/(\\d+)',
                input_path_regex_capture_groups => 'table,year,month,day,hour',
                table_blacklist_regex           => '^Edit|ChangesListHighlights|InputDeviceDynamics$',
                # Deduplicate basd on uuid field and geocode ip in EventLogging analytics data.
                transform_functions             => 'org.wikimedia.analytics.refinery.job.refine.deduplicate_eventlogging,org.wikimedia.analytics.refinery.job.refine.geocode_ip',
            }),
            minute     => 30,
        }

        # Refine EventBus data.
        profile::analytics::refinery::job::refine_job { 'eventlogging_eventbus':
            job_config => merge($default_config, {
                input_path                      => '/wmf/data/raw/event',
                input_path_regex                => '.*(eqiad|codfw)_(.+)/hourly/(\\d+)/(\\d+)/(\\d+)/(\\d+)',
                input_path_regex_capture_groups => 'datacenter,table,year,month,day,hour',
                table_blacklist_regex           => '^mediawiki_page_properties_change|mediawiki_recentchange$',
                # Deduplicate eventbus based data based on meta.id field
                transform_functions             => 'org.wikimedia.analytics.refinery.job.refine.deduplicate_eventbus',
            }),
            minute     => 20,
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
            minute     => 25,
        }

        # Netflow data
        profile::analytics::refinery::job::refine_job { 'netflow':
            job_config         => merge($default_config, {
                # This is imported by camus_job { 'netflow': }
                input_path                      => '/wmf/data/raw/netflow',
                input_path_regex                => '(netflow)/hourly/(\\d+)/(\\d+)/(\\d+)/(\\d+)',
                input_path_regex_capture_groups => 'table,year,month,day,hour',
                output_path                     => '/wmf/data/wmf',
                database                        => 'wmf',
            }),
            minute             => 45,
            monitoring_enabled => false,
        }
    }
}
