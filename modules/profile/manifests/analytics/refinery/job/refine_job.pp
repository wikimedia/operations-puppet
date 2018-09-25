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
# == Properties
#
# [*job_config*]
#   A hash of job config properites that will be rendered as a .properties file and
#   given to the Refine job as the --config_file argument.
#
# [*job_name*]
#   The Spark job name. Default: refine_$title
#
define profile::analytics::refinery::job::refine_job (
    $job_config,
    $job_name            = "refine_${title}",
    $monitoring_enabled  = true,
    $refinery_job_jar    = undef,
    $job_class           = 'org.wikimedia.analytics.refinery.job.refine.Refine',
    $queue               = 'production',
    $spark_driver_memory = '8G',
    $spark_max_executors = 64,
    $spark_extra_opts    = '',
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

    # refine job properties will go in /etc/refinery/refine
    $job_config_dir = "${::profile::analytics::refinery::config_dir}/refine"
    if !defined(File[$job_config_dir]) {
        file { $job_config_dir:
            ensure => 'directory',
        }
    }

    # If $refinery_job_jar not given, use the symlink at artifacts/refinery-job.jar
    $_refinery_job_jar = $refinery_job_jar ? {
        undef   => "${refinery_path}/artifacts/refinery-job.jar",
        default => $refinery_job_jar,
    }

    $job_config_file = "${job_config_dir}/${job_name}.properties"
    profile::analytics::refinery::job::config { $job_config_file:
        ensure     => $ensure,
        properties => $job_config,
    }

    profile::analytics::refinery::job::spark_job { $job_name:
        ensure     => $ensure,
        jar        => $_refinery_job_jar,
        class      => $job_class,
        # We use spark's --files option to load the $job_config_file to the Spark job's working HDFS dir.
        # It is then referenced via its relative file name with --config_file $job_name.properties.
        spark_opts => "--files /etc/hive/conf/hive-site.xml,${job_config_file} --master yarn --deploy-mode cluster --queue ${queue} --driver-memory ${spark_driver_memory} --conf spark.driver.extraClassPath=/usr/lib/hive/lib/hive-jdbc.jar:/usr/lib/hadoop-mapreduce/hadoop-mapreduce-client-common.jar:/usr/lib/hive/lib/hive-service.jar --conf spark.dynamicAllocation.maxExecutors=${spark_max_executors} ${spark_extra_opts}",
        job_opts   => "--config_file ${job_name}.properties",
        require    => Profile::Analytics::Refinery::Job::Config[$job_config_file],
        user       => $user,
        hour       => $hour,
        minute     => $minute,
        month      => $month,
        monthday   => $monthday,
        weekday    => $weekday,
    }

    # Look back over a 24 period before 4 hours ago and ensure that all expected
    # refined datasets for this job are present.
    if $ensure and $monitoring_enabled {
        $ensure_monitor = 'present'
    }
    else {
        $ensure_monitor = 'absent'
    }
    $monitor_since = 28
    $monitor_until = 4

    # NOTE: RefineMonitor should not be run in YARN.
    # Local mode is fine.
    profile::analytics::refinery::job::spark_job { "monitor_${job_name}":
        ensure   => $ensure_monitor,
        jar      => $_refinery_job_jar,
        class    => 'org.wikimedia.analytics.refinery.job.refine.RefineMonitor',
        # Use the same config file as the Refine job, but override the since and until
        # to avoid looking back so far when checking for missing data.
        job_opts => "--config_file ${job_config_file} --since ${monitor_since} --until ${monitor_until}",
        require  => Profile::Analytics::Refinery::Job::Config[$job_config_file],
        user     => $user,
        hour     => 4,
        minute   => 15,
    }

}
