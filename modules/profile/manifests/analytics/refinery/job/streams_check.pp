# == Class profile::analytics::refinery::job::streams_check
#
# Deploy cron scripts able to check and restart (if needed) streaming jobs
# running on the Hadoop cluster that might have failed. This profile does not
# take care of alarming, that needs to be done separately.
#

class profile::analytics::refinery::job::streams_check {
    require ::profile::analytics::refinery

    # Shortcut var to DRY up cron commands.
    $refinery_path = $profile::analytics::refinery::path

    $refinery_job_jar = "${refinery_path}/artifacts/refinery-job.jar"
    $spark_num_executors = 4
    $spark_executor_cores = 3
    $spark_driver_memory = '2G'
    $spark_executor_memory = '4G'
    $druid_segment_gran = 'HOUR'
    $tranq_window_period = 'PT10M'
    $batch_duration_secs = '60'
    $job_name = 'BannerImpressionsStream'

    # No log needed as job runs in cluster mode
    $command = "PYTHONPATH=${refinery_path}/python ${refinery_path}/bin/is-yarn-app-running ${job_name} || /usr/bin/spark2-submit --master yarn --deploy-mode cluster --queue production --conf spark.dynamicAllocation.enabled=false --driver-memory ${spark_driver_memory} --executor-memory ${spark_executor_memory} --executor-cores ${spark_executor_cores} --num-executors ${spark_num_executors} --class org.wikimedia.analytics.refinery.job.druid.BannerImpressionsStream --name ${job_name} ${refinery_job_jar} --druid-indexing-segment-granularity ${druid_segment_gran} --druid-indexing-window-period ${tranq_window_period} --batch-duration-seconds ${batch_duration_secs} > /dev/null 2>&1"

    # This checks for banner streaming job running in Yarn, and relaunches it if needed.
    cron { 'refinery-relaunch-banner-streaming':
        command     => $command,
        environment => 'MAILTO=analytics-alerts@wikimedia.org',
        user        => 'hdfs',
        minute      => '*/5'
    }
}
