# == Define profile::analytics::refinery::job::refine_job
#
# Installs a cron job to run the Refine Spark job.  This is
# used to import arbitrary JSON data (EventLogging, EventBus, etc.)
# into Hive.
#
# If $refine_monitor_enabled is true, a daily RefineMonitor job will be
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
# [*interval*]
#   Systemd time interval.
#   Default: '*-*-* *:00:00' (hourly)
#
define profile::analytics::refinery::job::refine_job (
    $job_config,
    $job_name               = "refine_${title}",
    $refine_monitor_enabled = true,
    $monitoring_enabled     = true,
    $refinery_job_jar       = undef,
    $job_class              = 'org.wikimedia.analytics.refinery.job.refine.Refine',
    $monitor_class          = 'org.wikimedia.analytics.refinery.job.refine.RefineMonitor',
    $queue                  = 'production',
    $spark_driver_memory    = '8G',
    $spark_max_executors    = 64,
    $spark_extra_opts       = '',
    $user                   = 'analytics',
    $interval               = '*-*-* *:00:00',
    $ensure                 = 'present',
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

    # We need to load an older CDH's version of these Hive jars in order to use
    # Hive JDBC directly inside of a spark job.  This is a workaround for
    # https://issues.apache.org/jira/browse/SPARK-23890.
    # See also:
    # https://github.com/wikimedia/analytics-refinery/blob/master/artifacts/hive-cdh5.10.0.README
    # https://phabricator.wikimedia.org/T209407
    # Because these older CDH hive jars are no longer deployed throughout the cluster,
    # we need to include them in --files to upload them to the YARN AM/Spark Driver container.
    $driver_extra_hive_jars = "${refinery_path}/artifacts/hive-jdbc-1.1.0-cdh5.10.0.jar,${refinery_path}/artifacts/hive-service-1.1.0-cdh5.10.0.jar"
    # We need hadoop-mapreduce-client-common which IS deployed throughout the cluster,
    # as well as the aforementioned CDH 5.10.0 hive jars, which have will be uploaded to the
    # Spark Driver's working dir, and should be referenced by relative path.
    $driver_extra_classpath = '/usr/lib/hadoop-mapreduce/hadoop-mapreduce-client-common.jar:hive-jdbc-1.1.0-cdh5.10.0.jar:hive-service-1.1.0-cdh5.10.0.jar'

    profile::analytics::refinery::job::spark_job { $job_name:
        ensure             => $ensure,
        jar                => $_refinery_job_jar,
        class              => $job_class,
        # We use spark's --files option to load the $job_config_file to the Spark job's working HDFS dir.
        # It is then referenced via its relative file name with --config_file $job_name.properties.
        spark_opts         => "--files /etc/hive/conf/hive-site.xml,${job_config_file},${driver_extra_hive_jars} --master yarn --deploy-mode cluster --queue ${queue} --driver-memory ${spark_driver_memory} --conf spark.driver.extraClassPath=${driver_extra_classpath} --conf spark.dynamicAllocation.maxExecutors=${spark_max_executors} ${spark_extra_opts}",
        job_opts           => "--config_file ${job_name}.properties",
        require            => Profile::Analytics::Refinery::Job::Config[$job_config_file],
        user               => $user,
        interval           => $interval,
        monitoring_enabled => $monitoring_enabled,
    }

    # Look back over a 24 period before 4 hours ago and ensure that all expected
    # refined datasets for this job are present.
    if $ensure and $refine_monitor_enabled {
        $ensure_monitor = 'present'
    }
    else {
        $ensure_monitor = 'absent'
    }
    $monitor_since = 28
    $monitor_until = 4

    if $interval {
        $monitor_interval = '*-*-* 04:15:00'
    } else {
        $monitor_interval = undef
    }

    # NOTE: RefineMonitor should not be run in YARN.
    # Local mode is fine.
    profile::analytics::refinery::job::spark_job { "monitor_${job_name}":
        ensure             => $ensure_monitor,
        jar                => $_refinery_job_jar,
        class              => $monitor_class,
        # Use the same config file as the Refine job, but override the since and until
        # to avoid looking back so far when checking for missing data.
        job_opts           => "--config_file ${job_config_file} --since ${monitor_since} --until ${monitor_until}",
        require            => Profile::Analytics::Refinery::Job::Config[$job_config_file],
        user               => $user,
        interval           => $monitor_interval,
        monitoring_enabled => $monitoring_enabled,
    }

}
