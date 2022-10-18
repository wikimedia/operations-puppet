# == Define profile::analytics::refinery::job::refine_job
#
# Installs a systemd timer to run the Refine Spark job.  This is
# used to import arbitrary (schemaed) JSON data into Hive.
#
# If $refine_monitor_enabled is true, a daily RefineMonitor job will be
# scheduled to look back over a 48 hour period to ensure that all
# datasets expected to be refined were successfully done so, or if
# any _FAILURE flags exist.
#
# For description of the Refine $job_config parameters, see:
# https://github.com/wikimedia/analytics-refinery-source/blob/master/refinery-job/src/main/scala/org/wikimedia/analytics/refinery/job/refine/Refine.scala
#
# == Properties
#
# [*job_config*] (required)
#   A hash of job config properites that will be rendered as a .properties file and
#   given to the Refine job as the --config_file argument.
#
# [*monitor_interval*] (required)
#   Systemd time interval for running the RefineMonitor job.
#
# [*job_name*]
#   The Spark job name. Default: refine_$title
#
# [*interval*]
#   Systemd time interval.
#   Default: '*-*-* *:00:00' (hourly)
#
# [*monitor_since*]
#   If refine_monitor_enabled, RefineMonitor should use the same settings as the
#   main Refine job, but likely with a wider range of data to check.
#   Instead of re-rendering an entirely different job config file, use the same
#   one as the main Refine job, but with CLI flags to override --since to $monitor_since.
#   Default: 48 hours ago.
#
# [*monitor_until*]
#   If refine_monitor_enabled, RefineMonitor should use the same settings as the
#   main Refine job, but likely with a wider range of data to check.
#   Instead of re-rendering an entirely different job config file, use the same
#   one as the main Refine job, but with CLI flags to override --until to $monitor_until.
#   Default: 4 hours ago.
#
# [*send_mail*]
#   If true, service failures will alert, e.g. a bad exit code from Refine or RefineMonitor
#   will result in an email sent to Analytics/DSE
#
# [*refine_monitor_enabled*]
#   If true, a RefineMonitor job will be scheduled using the same job_config
#   for Refine plus any refine_monitor_job_config overrides. RefineMonitor
#   alerts on missing dataset hours or failure flags.
define profile::analytics::refinery::job::refine_job (
    $job_config,
    $monitor_interval,
    $job_name                         = "refine_${title}",
    $refinery_job_jar                 = undef,
    $job_class                        = 'org.wikimedia.analytics.refinery.job.refine.Refine',
    $monitor_class                    = 'org.wikimedia.analytics.refinery.job.refine.RefineMonitor',
    $monitor_since                    = 48,
    $monitor_until                    = 4,
    $queue                            = 'production',
    $spark_executor_memory            = '4G',
    $spark_executor_cores             = 1,
    $spark_driver_memory              = '8G',
    $spark_max_executors              = 64,
    $spark_extra_files                = undef,
    $spark_extra_opts                 = '',
    $deploy_mode                      = 'cluster',
    $user                             = 'analytics',
    $interval                         = '*-*-* *:00:00',
    $send_mail                        = true,
    $refine_monitor_enabled           = $send_mail,
    $ensure                           = 'present',
    $use_keytab                       = false,
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

    # All spark jobs declared here share these parameters.
    Profile::Analytics::Refinery::Job::Spark_job {
        jar                => $_refinery_job_jar,
        require            => Profile::Analytics::Refinery::Job::Config[$job_config_file],
        user               => $user,
        send_mail          => $send_mail,
        use_keytab         => $use_keytab,
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

    # If $spark_extra_files is given, append it with a comma to existing files.
    $_spark_extra_files = $spark_extra_files ? {
        undef   => '',
        default => ",${spark_extra_files}",
    }

    $config_file_path = $deploy_mode ? {
        'client' => $job_config_file,
        default  => "${job_name}.properties",
    }

    # In DataFrameToHive we issue CREATE/ALTER sql statement to Hive if needed.
    # Spark is not aware of this code and by default it retrieves Delegation Tokens
    # only for HDFS/Hive-Metastore/HBase. When the JDBC connection to the Hive Server 2
    # is established (with Kerberos enabled), some credentials will be needed to be able
    # to login as $user. These credentials are explicitly provided as keytab, that is copied
    # (securely) by Yarn to its distributed cache.
    profile::analytics::refinery::job::spark_job { $job_name:
        ensure     => $ensure,
        class      => $job_class,
        # We use spark's --files option to load the $job_config_file to the Spark job's working HDFS dir.
        # It is then referenced via its relative file name with --config_file $job_name.properties.
        spark_opts => "--files /etc/hive/conf/hive-site.xml,${job_config_file},${driver_extra_hive_jars}${_spark_extra_files} --master yarn --deploy-mode ${deploy_mode} --queue ${queue} --driver-memory ${spark_driver_memory} --executor-memory ${spark_executor_memory} --executor-cores ${spark_executor_cores} --conf spark.driver.extraClassPath=${driver_extra_classpath} --conf spark.dynamicAllocation.maxExecutors=${spark_max_executors} ${spark_extra_opts}",
        job_opts   => "--config_file ${config_file_path}",
        interval   => $interval,
    }


    # NOTE: RefineMonitor should not be run in YARN,
    # as they only look in HDFS paths and don't crunch any data.

    # Look back over a 48 period before 4 hours ago and ensure that all expected
    # refined datasets for this job are present and no _FAILURE flags exist.
    if $ensure == 'present' and $refine_monitor_enabled {
        $ensure_monitor = 'present'
    }
    else {
        $ensure_monitor = 'absent'
    }
    profile::analytics::refinery::job::spark_job { "monitor_${job_name}":
        ensure    => $ensure_monitor,
        class     => $monitor_class,
        # Use the same config file as the Refine job, but override the since and until.
        job_opts  => "--config_file ${job_config_file} --since ${monitor_since} --until ${monitor_until}",
        interval  => $monitor_interval,
        send_mail => $send_mail,
    }

}
