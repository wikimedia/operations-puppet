# Class: profile::analytics::refinery::job::test::refine_sanitize
#
# Sets up RefineSanitize jobs for the analytics test cluster.
# These jobs only sanitize a limited number of tables for testing purposes.
#
# Parameters:
#
# [*refinery_version*]
#   Version of org.wikmidia.analytics.refinery.job refinery-job.jar to use.
#
# [*ensure_timers*]
#   Default: true
#
# [*use_kerberos_keytab*]
#   Default: true
#
class profile::analytics::refinery::job::test::refine_sanitize(
    String $refinery_version      = lookup('profile::analytics::refinery::job::test::refine_sanitize::refinery_version', { 'default_value' => '0.1.5' }),
    Wmflib::Ensure $ensure_timers = lookup('profile::analytics::refinery::job::test::refine_sanitize::ensure_timers', { 'default_value' => 'present' }),
    Boolean $use_kerberos_keytab  = lookup('profile::analytics::refinery::job::test::refine_sanitize::use_kerberos_keytab', { 'default_value' => true }),
) {
    require ::profile::analytics::refinery
    require ::profile::hive::client

    $refinery_path = $::profile::analytics::refinery::path
    $refinery_config_dir = $::profile::analytics::refinery::config_dir
    $refinery_job_jar = "${refinery_path}/artifacts/org/wikimedia/analytics/refinery/refinery-job-${refinery_version}.jar"

    # Declare salts needed for refine_sanitize jobs.  If you make new sanitize jobs that need
    # different salts, be sure to declare them here.
    # Salts will end up in /etc/refinery/salts and /user/hdfs/salts
    $refine_sanitize_salts = [
        'eventlogging_sanitization'
    ]
    class { '::profile::analytics::refinery::job::refine_sanitize_salt_rotate':
        salt_names          => $refine_sanitize_salts,
        ensure_timers       => $ensure_timers,
        use_kerberos_keytab => $use_kerberos_keytab
    }
    $hdfs_salts_prefix = $::profile::analytics::refinery::job::refine_sanitize_salt_rotate::hdfs_salts_prefix


    # Defaults for all refine_jobs declared here.
    Profile::Analytics::Refinery::Job::Refine_job {
        ensure              => $ensure_timers,
        use_keytab          => $use_kerberos_keytab,
        refinery_job_jar    => $refinery_job_jar,
        job_class           => 'org.wikimedia.analytics.refinery.job.refine.RefineSanitize',
        monitor_class       => 'org.wikimedia.analytics.refinery.job.refine.RefineSanitizeMonitor',
        spark_extra_opts    => '--conf spark.ui.retainedStage=20 --conf spark.ui.retainedTasks=1000 --conf spark.ui.retainedJobs=100',
    }


    # RefineSanitize job declarations go below.

    # EventLogging sanitization. Runs in two steps.
    # Common parameters for both jobs:
    $eventlogging_sanitization_job_config = {
        'input_database'      => 'event',
        # in test, we only refine and sanitize NavigationTiming for legacy EventLogging data.
        'table_include_regex' => '^navigationtiming$',
        'output_database'     => 'event_sanitized',
        'output_path'         => '/wmf/data/event_sanitized',
        'allowlist_path'      => '/wmf/refinery/current/static_data/eventlogging/whitelist.yaml',
        'salts_path'          => '/user/hdfs/salts/eventlogging_sanitization',
        'parallelism'         => '16',
        'should_email_report' => true,
        'to_emails'           => 'analytics-alerts@wikimedia.org',
    }

    # Execute 1st sanitization pass, right after data collection. Runs once per hour.
    # Job starts a couple minutes after the hour, to leave time for the salt files to be updated.
    profile::analytics::refinery::job::refine_job { 'sanitize_eventlogging_analytics_immediate_test':
        interval   => '*-*-* *:02:00',
        job_config => $eventlogging_sanitization_job_config,
    }
    # Execute 2nd sanitization pass, after 45 days of collection.
    # Runs once per day at a less busy time.
    profile::analytics::refinery::job::refine_job { 'sanitize_eventlogging_analytics_delayed_test':
        interval   => '*-*-* 06:00:00',
        job_config => $eventlogging_sanitization_job_config.merge({
            'since' => 1104,
            'until' => 1080,
        }),
    }
}
