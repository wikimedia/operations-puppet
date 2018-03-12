# == Define profile::analytics::refinery::job::refine_job
#
# Installs a cron job to run the Refine Spark job.  This is
# used to import arbitrary JSON data (EventLogging, EventBus, etc.)
# into Hive.
#
# If $monitoring_enabled is true, a daily RefineMonitor job will be
# scheduled to look back over a 24 hour period to ensure that all
# datasets expected to be refined were successfully done so.
#
# For description of the parameters, see:
# https://github.com/wikimedia/analytics-refinery-source/blob/master/refinery-job/src/main/scala/org/wikimedia/analytics/refinery/job/refine/Refine.scala
#
define profile::analytics::refinery::job::refine_job (
    $input_base_path,
    $input_regex,
    $input_capture,
    $output_base_path,
    $output_database,
    $refinery_job_jar    = undef,
    $queue               = 'production',
    $email_to            = 'analytics-alerts@wikimedia.org',
    $spark_driver_memory = '8G',
    $spark_max_executors = 64,
    $parallelism         = 12,
    $since               = 96, # 4 days
    $table_whitelist     = undef,
    $table_blacklist     = undef,
    $transform_functions = undef,
    $monitoring_enabled  = true,
    $user                = 'hdfs',
    $hour                = undef,
    $minute              = undef,
    $month               = undef,
    $monthday            = undef,
    $weekday             = undef,
    $ensure              = 'present',
) {
    require ::profile::analytics::refinery

    $refinery_path = $profile::analytics::refinery::path

    # If $refinery_job_jar not given, use the symlink at artifacts/refinery-job.jar
    $_refinery_job_jar = $refinery_job_jar ? {
        undef   => "${refinery_path}/artifacts/refinery-job.jar",
        default => $refinery_job_jar,
    }

    $job_name = "refine_${title}"
    $log_file = "${profile::analytics::refinery::log_dir}/${job_name}.log"

    # Build whitelist or blacklist table option
    if $table_whitelist {
        $whitelist_blacklist_opt = "--table-whitelist '${table_whitelist}'"
    }
    elsif $table_blacklist {
        $whitelist_blacklist_opt = "--table-blacklist '${table_blacklist}'"
    }
    else {
        $whitelist_blacklist_opt = ''
    }

    $transform_functions_opt = $transform_functions ? {
        undef   => '',
        default =>"--transform-functions ${transform_functions}"
    }

    # Only send email report if $email_to provided.
    $email_opts = $email_to ? {
        undef   => '',
        default => "--send-email-report --to-emails ${email_to}"
    }

    # The command here can end up being pretty long, especially if the table whitelist
    # or blacklist is long.  Crontabs have a line length limit, so we render this
    # command into a script and then install that as the cron job.
    $refine_command = "PYTHONPATH=${refinery_path}/python ${refinery_path}/bin/is-yarn-app-running ${job_name} || /usr/bin/spark-submit --master yarn --deploy-mode cluster --queue ${queue} --driver-memory ${spark_driver_memory} --conf spark.dynamicAllocation.maxExecutors=${spark_max_executors} --files /etc/hive/conf/hive-site.xml --class org.wikimedia.analytics.refinery.job.refine.Refine --name ${job_name} ${_refinery_job_jar} --parallelism ${parallelism} --since ${since} ${whitelist_blacklist_opt} ${email_opts} --input-base-path ${input_base_path} --input-regex '${input_regex}' --input-capture '${input_capture}' --output-base-path ${output_base_path} --database ${output_database} ${$transform_functions_opt}"
    $refine_script = "/usr/local/bin/${job_name}"
    file { $refine_script:
        ensure  => $ensure,
        content => $refine_command,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
    }

    cron { $job_name:
        ensure   => $ensure,
        command  => "${refine_script} >> ${log_file} 2>&1",
        user     => $user,
        hour     => $hour,
        minute   => $minute,
        month    => $month,
        monthday => $monthday,
        weekday  => $weekday,
        require  => File[$refine_script],
    }


    # Look back over a 24 period before 4 hours ago and ensure that all expected
    # refined datasets for this job are present.
    if $ensure and $monitoring_enabled {
        $ensure_monitor = 'present'
    }
    else {
        $ensure_monitor = 'absent'
    }

    $monitor_job_name = "refine_monitor_${title}"
    $monitor_log_file = "${profile::analytics::refinery::log_dir}/${monitor_job_name}.log"
    $monitor_since    = 28
    $monitor_until    = 4
    $monitor_command  = "/usr/bin/spark-submit --master yarn --deploy-mode cluster --queue ${queue} --class org.wikimedia.analytics.refinery.job.refine.RefineMonitor --name ${monitor_job_name} ${_refinery_job_jar} --since ${monitor_since} --until ${monitor_until} ${whitelist_blacklist_opt} ${email_opts} --input-base-path ${input_base_path} --input-regex '${input_regex}' --input-capture '${input_capture}' --output-base-path ${output_base_path} --database ${output_database}"
    $monitor_script   = "/usr/local/bin/${monitor_job_name}"

    file { $monitor_script:
        ensure  => $ensure_monitor,
        content => $monitor_command,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
    }

    # Run this RefineMonitor job daily at 04:15
    cron { $monitor_job_name:
        ensure  => $ensure_monitor,
        command => "${monitor_script} >> ${monitor_log_file} 2>&1",
        user    => $user,
        hour    => 4,
        minute  => 15,
        require => File[$monitor_script],
    }

}
