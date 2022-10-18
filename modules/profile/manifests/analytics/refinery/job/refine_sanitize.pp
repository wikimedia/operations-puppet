# Class: profile::analytics::refinery::job::refine_sanitize
#
# Sets up RefineSanitize jobs for the analytics test cluster.
#
# Description of Refine jobs declared here:
# - event_sanitized_main
#   Sanitizes tables declared in event_sanitized_main_allowlist.yaml from
#   event -> event_sanitized db, with the keep_all hash config enabled.
#
# - event_sanitized_analytics
#   Sanitizes tables declared in event_sanitized_analytics_allowlist from
#   event -> event_sanitized db, with the keep_all hash config disabled.
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
class profile::analytics::refinery::job::refine_sanitize(
    String $refinery_version      = lookup('profile::analytics::refinery::job::refine_sanitize::refinery_version', { 'default_value' => '0.1.15' }),
    Wmflib::Ensure $ensure_timers = lookup('profile::analytics::refinery::job::refine_sanitize::ensure_timers', { 'default_value' => 'present' }),
    Boolean $use_kerberos_keytab  = lookup('profile::analytics::refinery::job::refine_sanitize::use_kerberos_keytab', { 'default_value' => true }),
) {
    require ::profile::analytics::refinery
    require ::profile::hive::client

    $refinery_path = $::profile::analytics::refinery::path
    $refinery_config_dir = $::profile::analytics::refinery::config_dir
    $refinery_job_jar = "${refinery_path}/artifacts/org/wikimedia/analytics/refinery/refinery-job-${refinery_version}.jar"

    # Declare salts needed for refine_sanitize jobs.  If you make new sanitize jobs that need
    # different salts, be sure to declare them here.
    # Salts will end up in /etc/refinery/salts and /user/hdfs/salts
    # Most likely, you will only need one salt, so that fields hashed during the same
    # time period can be associated properly.
    $refine_sanitize_salts = [
        'event_sanitized',
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
        spark_driver_memory => '16G',
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
        spark_extra_opts      => '--conf spark.executor.memoryOverhead=4096 --conf spark.ui.retainedStage=20 --conf spark.ui.retainedTasks=1000 --conf spark.ui.retainedJobs=100',
    }

    # There are several jobs that run RefineSanitize from event into event_sanitized.
    # They use different allowlists and different keep_all_enabled settings.
    # This is the common config shared by all of them.
    $event_sanitized_common_job_config = {
        'input_database'      => 'event',
        'output_database'     => 'event_sanitized',
        'output_path'         => '/wmf/data/event_sanitized',
        'salts_path'          => "${hdfs_salts_prefix}/event_sanitized",
        'should_email_report' => true,
        'to_emails'           => 'data-engineering-alerts@lists.wikimedia.org',
    }

    # RefineSanitize job declarations go below.
    # Each job has an 'immediate' and a 'delayed' version.
    # immediate is executed right after data collection. Runs once per hour.
    # delayed is excuted on data that is 45 days old, to allow for automated backfilling
    # data in the input database if it has changed since the immediate sanitize job ran.
    # Jobs starts a few minutes after the hour, to leave time for the salt files to be updated.
    $delayed_since = 1104 # 46 days ago
    $delayed_until = 1080 # 45 days ago


    # == event_sanitized_main
    # Sanitizes non analytics (and non legacy eventlogging) event data, with keep_all enabled.
    $event_sanitized_main_job_config = $event_sanitized_common_job_config.merge({
        'allowlist_path'   => '/wmf/refinery/current/static_data/sanitization/event_sanitized_main_allowlist.yaml',
        'keep_all_enabled' => true,
    })
    profile::analytics::refinery::job::refine_job { 'event_sanitized_main_immediate':
        interval         => '*-*-* *:05:00',
        monitor_interval => '*-*-* 04:15:00',
        job_config       => $event_sanitized_main_job_config
    }
    profile::analytics::refinery::job::refine_job { 'event_sanitized_main_delayed':
        interval         => '*-*-* 05:00:00',
        # Monitor with a couple hours delay to allow for refine to finish.
        monitor_interval => '*-*-* 07:00:00',
        # The monitor job checks the last 48 hours processed.
        # Since the monitor job started a couple hours after the refine job,
        # those hours need to be counted when defining monitor since and until.
        monitor_since    => $delayed_since + 26,
        monitor_until    => $delayed_until + 2,
        job_config       => $event_sanitized_main_job_config.merge({
            'since' => $delayed_since,
            'until' => $delayed_until,
        }),
    }


    # == event_sanitized_analytics
    # Sanitizes analytics event tables, including legacy eventlogging tables, with keep_all disabled.
    $event_sanitized_analytics_job_config = $event_sanitized_common_job_config.merge({
        'allowlist_path'   => '/wmf/refinery/current/static_data/sanitization/event_sanitized_analytics_allowlist.yaml',
        'keep_all_enabled' => false,
    })
    profile::analytics::refinery::job::refine_job { 'event_sanitized_analytics_immediate':
        interval         => '*-*-* *:02:00',
        monitor_interval => '*-*-* 04:20:00',
        job_config       => $event_sanitized_analytics_job_config,
    }
    profile::analytics::refinery::job::refine_job { 'event_sanitized_analytics_delayed':
        interval         => '*-*-* 06:00:00',
        # Monitor with a couple hours delay to allow for refine to finish.
        monitor_interval => '*-*-* 08:00:00',
        # The monitor job checks the last 48 hours processed.
        # Since the monitor job started a couple hours after the refine job,
        # those hours need to be counted when defining monitor since and until.
        monitor_since    => $delayed_since + 26,
        monitor_until    => $delayed_until + 2,
        job_config       => $event_sanitized_analytics_job_config.merge({
            'since' => $delayed_since,
            'until' => $delayed_until,
        }),
    }

}
