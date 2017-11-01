# == Define role::analytics_cluster::refinery::job::json_refine_job
#
# Installs a cron job to run the JsonRefine Spark job.  This is
# used to import arbitrary JSON data (EventLogging, EventBus, etc.)
# into Hive.
#
# For description of the parameters, see:
# https://github.com/wikimedia/analytics-refinery-source/blob/master/refinery-job/src/main/scala/org/wikimedia/analytics/refinery/job/JsonRefine.scala
define role::analytics_cluster::refinery::job::json_refine_job (
    $input_base_path,
    $input_regex,
    $input_capture,
    $output_base_path,
    $output_database,
    $refinery_job_jar    = undef,
    $email_to            = 'analytics-alerts@wikimedia.org',
    $spark_driver_memory = '8G',
    $spark_max_executors = 64,
    $parallelism         = 12,
    $since               = 96, # 4 days
    $table_whitelist     = undef,
    $table_blacklist     = undef,
    $user                = 'hdfs',
    $hour                = undef,
    $minute              = undef,
    $month               = undef,
    $monthday            = undef,
    $weekday             = undef,
    $ensure              = 'present',
) {
    require ::role::analytics_cluster::refinery

    $refinery_path = $role::analytics_cluster::refinery::path

    # If $refinery_job_jar not given, use the symlink at artifacts/refinery-job.jar
    $_refinery_job_jar = $refinery_job_jar ? {
        undef => $refinery_job_jar,
        default => "${refinery_path}/artifacts/refinery-job.jar",
    }

    $job_name = "json_refine_${title}"
    $log_file = "${role::analytics_cluster::refinery::log_dir}/${job_name}.log"

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

    # Only send email report if $email_to provided.
    $email_opts = $email_to ? {
        undef => '',
        default => "--send-email-report --to-emails ${email_to}"
    }

    $command = "PYTHONPATH=${refinery_path}/python ${refinery_path}/bin/is-yarn-app-running || /usr/bin/spark-submit --master yarn --deploy-mode client --driver-memory ${spark_driver_memory} --conf spark.dynamicAllocation.maxExecutors=${spark_max_executors} --class org.wikimedia.analytics.refinery.job.JsonRefine --name ${job_name} ${_refinery_job_jar} --parallelism ${parallelism} --since ${since} ${whitelist_blacklist_opt} ${email_opts} --input-base-path ${input_base_path} --input-regex '${input_regex}' --input-capture '${input_capture}' --output-base-path ${output_base_path} --output-database ${output_database} >> ${log_file} 2>&1"

    cron { $job_name:
        command  => $command,
        user     => $user,
        hour     => $hour,
        minute   => $minute,
        month    => $month,
        monthday => $monthday,
        weekday  => $weekday,
    }
}
