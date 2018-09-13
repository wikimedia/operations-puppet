# == Define profile::analytics::refinery::job::refine_job
#
# Renders a spark2-submit wrapper script and sets up a cron to run it.
#
# == Properties
#
# [*jar*]
#   Path to Spark job .jar file
#
# [*class*]
#   Spark job main class name.
#
# [*job_name*]
#   Name of this spark job; will be used for script, cron job, and Spark --name.
#   Default: $title
#
# [*spark_opts*]
#   Extra Spark CLI opts to be passed to spark2-submit
#
# [*job_opts*]
#   CLI opts to append to the spark2-submit command; these will be passed to your main
#   function as args.
#
# [*log_file*]
#   Default: /var/log/refinery/$job_name.log
#
define profile::analytics::refinery::job::spark_job(
    $jar,
    $class,
    $job_name            = $title,
    $spark_opts          = undef,
    $job_opts            = undef,
    $log_file            = "/var/log/refinery/${job_name}.log",
    $user                = 'hdfs',
    $hour                = undef,
    $minute              = undef,
    $month               = undef,
    $monthday            = undef,
    $weekday             = undef,
    $ensure              = 'present',
)
{
    require ::profile::analytics::refinery
    $refinery_path = $profile::analytics::refinery::path

    $script = "/usr/local/bin/${job_name}"

    file { $script:
        ensure  => $ensure,
        content => template('profile/analytics/refinery/job/spark_job.sh.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
    }

    cron { $job_name:
        ensure   => $ensure,
        command  => "${script} >> ${log_file} 2>&1",
        user     => $user,
        hour     => $hour,
        minute   => $minute,
        month    => $month,
        monthday => $monthday,
        weekday  => $weekday,
        require  => File[$script],
    }
}
