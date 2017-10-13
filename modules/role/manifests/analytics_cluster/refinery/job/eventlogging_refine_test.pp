# == Class role::analytics_cluster::refinery::job::eventlogging_refine_test
#
# Note: This file is temporary. It serves testing purposes described in
# https://phabricator.wikimedia.org/T177783. It should be removed after the
# experiment is finished.
#
# Installs a cron job to refine EventLogging:Popups json data into a
# partitioned hive external table.
#
class role::analytics_cluster::refinery::job::eventlogging_refine_test {
    require ::role::analytics_cluster::refinery

    # Use this log file.
    $eventlogging_refine_log_file = "${role::analytics_cluster::refinery::log_dir}/eventlogging_refine_test.log"

    # Send an email to analytics in case of failure.
    $mail_to = 'analytics-alerts@wikimedia.org'

    # The JsonRefine code is not deployed yet, so the used refinery jar lives in:
    $refinery_jar = '/mnt/hdfs/user/mforns/eventlogging_refine_test/refinery-job-0.0.49-SNAPSHOT.jar'

    # As we don't want to discuss final locations for refined EventLogging data yet,
    # output base path and output database for this job are:
    $output_base_path = '/user/tbayer/eventlogging_refine_test'
    $output_database  = 'tbayer'

    # Refine the EventLogging:Popups json data into a partitioned Hive table.
    # Starts 168 hours ago (one week), and ends 3 hours ago to avoid refining incomplete data.
    # Runs once every hour.
    cron { 'eventlogging-refine-test':
        command     => "spark-submit --class org.wikimedia.analytics.refinery.job.JsonRefine ${refinery_jar} --input-base-path /wmf/data/raw/eventlogging --database ${output_database} --output-base-path ${output_base_path} --input-regex 'eventlogging_(.+)/hourly/(\\d+)/(\\d+)/(\\d+)/(\\d+).*' --input-capture 'table,year,month,day,hour' --table-whitelist 'Popups' --since 168 --until 3 >> ${eventlogging_refine_log_file} 2>&1",
        environment => "MAILTO=${mail_to}",
        user        => 'hdfs',
        minute      => '0',
    }
}
