# == Class role::analytics_cluster::refinery::job::banner_stream
# Installs a cron checking every 5 minutes that the banner-activity spark
# streaming jobis running, and relaunches it otherwise.
#
# TEMPORARY: This class also installs a cron checking hourly for data
# to be present in druid for he past 10 minutes.
# This cron should be removed when we'll monitor realtime druid tasks
# using prometheus.
#

class role::analytics_cluster::refinery::job::banner_stream (
    $refinery_job_jar      = undef,
    $email_to              = 'analytics-alerts@wikimedia.org',
    $spark_num_executors   = 4,
    $spark_executor_cores  = 3,
    $spark_driver_memory   = '2G',
    $spark_executor_memory = 4G,
    $druid_segment_gran    = 'HOUR',
    $tranq_window_period   = 'PT10M',
    $batch_duration_secs   = '60'

){
    require ::role::analytics_cluster::refinery

    # Shortcut var to DRY up cron commands.
    $refinery_path = $role::analytics_cluster::refinery::path

    # If $refinery_job_jar not given, use the symlink at artifacts/refinery-job.jar
    $_refinery_job_jar = $refinery_job_jar ? {
        undef   => "${refinery_path}/artifacts/refinery-job.jar",
        default => $refinery_job_jar,
    }

    $job_name    = 'BannerImpressionsStream'

    # No log needed as job runs in cluster mode
    $command = "PYTHONPATH=${refinery_path}/python ${refinery_path}/bin/is-yarn-app-running ${job_name} || /usr/bin/spark2-submit --master yarn --deploy-mode cluster --driver-memory ${spark_driver_memory} --executor-memory ${spark_executor_memory} --executor-cores ${spark_executor_cores} --num-executors ${spark_num_executors} --class org.wikimedia.analytics.refinery.job.druid.BannerImpressionsStream --name ${job_name} ${_refinery_job_jar} --druid-indexing-segment-granularity ${druid_segment_gran} --druid-indexing-window-period ${tranq_window_period} --batch-duration-seconds ${batch_duration_secs} > /dev/null 2>&1"

    # This checks for banner streaming job running in Yarn, and relaunches it
    # if needed
    cron { 'refinery-relaunch-banner-streaming':
        command  => $command,
        user     => 'hdfs',
        minute   => '*/5'
    }

    ## TEMPORARY CRON FOR DATA CHECK

    $tmp_command = "if [ \"0\" -eq $(curl -H 'Content-Type: application/json' -XPOST --data-binary \"{\\\"queryType\\\":\\\"timeseries\\\",\\\"dataSource\\\":\\\"banner_activity_minutely\\\",\\\"granularity\\\":\\\"minute\\\",\\\"aggregations\\\":[{\\\"type\\\":\\\"count\\\",\\\"name\\\":\\\"events\\\"}],\\\"intervals\\\":[\\\"\$(date --date '-1 hour' +\\%Y-\\%m-\\%dT\\%H:\\%M:\\%S)/\$(date +\\%Y-\\%m-\\%dT\\%H:\\%M:\\%S)\\\"]}\" http://druid1001.eqiad.wmnet:8082/druid/v2/?pretty | wc -l) ]; then echo 'No data point in banner_activity_minutely for last hour! Please check.'; fi"
    cron { 'refinery-download-project-namespace-map':
        command  => $tmp_command,
        environment => "MAILTO=${email_to}",
        user     => 'hdfs',
        hour   => '*/1'
    }
}
